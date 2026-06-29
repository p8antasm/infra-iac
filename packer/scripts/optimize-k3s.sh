#!/bin/bash
set -e

echo "=== 1. Обновление системы и установка QEMU Agent ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install -y qemu-guest-agent curl sudo iptables ebtables socat conntrack apparmor setserial

# Включаем автозапуск QEMU Agent
systemctl enable qemu-guest-agent

echo "=== 2. Оптимизация sysctl параметров ядра под K3s и Cilium (eBPF) ==="
cat <<EOF > /etc/sysctl.d/99-k3s-cilium.conf
# Включение маршрутизации пакетов (необходимо для CNI)
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Оптимизация сети под высокие нагрузки (Cilium/eBPF)
net.core.somaxconn=32768
net.ipv4.tcp_max_syn_backlog=16384
net.core.netdev_max_backlog=16384

# Настройки для inotify (чтобы Loki/Promtail не упирались в лимиты при чтении логов)
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=524288

# Настройки лимитов памяти для mmap (важно для баз данных и Tempo/Loki)
vm.max_map_count=262144
EOF

sysctl --system

echo "=== 3. Настройка лимитов (Ulimits) для Loki/Tempo ==="
cat <<EOF >> /etc/security/limits.conf
*               soft    nofile          65535
*               hard    nofile          65535
*               soft    nproc           4096
*               hard    nproc           4096
EOF

echo "=== 4. Настройка модулей ядра для K3s и Cilium ==="
cat <<EOF > /etc/modules-load.d/k3s-modules.conf
br_netfilter
overlay
xt_REDIRECT
xt_owner
xt_statistic
EOF

echo "=== 5. Настройка монтирования bpffs (для Cilium eBPF) ==="
# Cilium автоматически монтирует bpffs в /sys/fs/bpf, но добавим явное правило, если необходимо
mkdir -p /sys/fs/bpf
echo "bpffs /sys/fs/bpf bpf rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab

echo "=== 6. Очистка образов и Cloud-Init ==="
# Сбрасываем cloud-init, чтобы при разворачивании новых машин генерировались уникальные настройки
cloud-init clean --logs

# Очистка логов и кэша apt
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f /etc/ssh/ssh_host_*
truncate -s 0 /etc/machine-id

echo "=== Сборка Golden Image успешно завершена! ==="

