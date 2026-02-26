#!/bin/bash

reload_nginx(){
  echo "Reloading Nginx..."
  if podman exec nginx-mailcow-app nginx -s reload 2>/dev/null; then
    echo "Nginx reloaded successfully"
  else
    echo "Could not reload Nginx, restarting container..."
    podman restart nginx-mailcow-app
  fi
}

reload_dovecot(){
  echo "Reloading Dovecot..."
  if podman exec dovecot-mailcow-app doveadm reload 2>/dev/null; then
    echo "Dovecot reloaded successfully"
  else
    echo "Could not reload Dovecot, restarting container..."
    podman restart dovecot-mailcow-app
  fi
}

reload_postfix(){
  echo "Reloading Postfix..."
  if podman exec postfix-mailcow-app postfix reload 2>/dev/null; then
    echo "Postfix reloaded successfully"
  else
    echo "Could not reload Postfix, restarting container..."
    podman restart postfix-mailcow-app
  fi
}

restart_container(){
  echo "Restarting ${1}..."
  podman restart "$1"
}

if [[ "${CERT_AMOUNT_CHANGED}" == "1" ]]; then
  restart_container nginx-mailcow-app
  restart_container dovecot-mailcow-app
  restart_container postfix-mailcow-app
else
  reload_nginx
  restart_container dovecot-mailcow-app
  restart_container postfix-mailcow-app
fi
