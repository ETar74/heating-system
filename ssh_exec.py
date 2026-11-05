# -*- coding: utf-8 -*-
"""ssh_exec.py — выполнение команд на TimeWeb-сервере по SSH (по ключу).
Использование: python ssh_exec.py "<команда>"
"""
import sys
import time
import paramiko

HOST = "129.101.112.11"
USER = "root"
PASSWORD = "b5UDgb,jDrnP+d"
KEYFILE = r"C:\Users\Admin\.ssh\id_ed25519"
FINGERPRINT = "SHA256:lOHdrcKYirEyQrvXAG/2hANAvxiDkxEf6aYQuQhsPhk"


def connect():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.RejectPolicy())
    client.connect(
        hostname=HOST,
        username=USER,
        password=PASSWORD,
        key_filename=KEYFILE,
        look_for_keys=True,
        allow_agent=True,
        timeout=60,
        banner_timeout=90,
        auth_timeout=90,
    )
    return client


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "echo no-command"

    last_err = None
    for attempt in range(1, 6):
        client = None
        try:
            client = connect()
            break
        except Exception as e:
            last_err = e
            print(f"[retry {attempt}/5] {str(e)[:200]}")
            time.sleep(8)

    if client is None:
        print(f"ALL RETRIES FAILED: {last_err}")
        sys.exit(1)

    try:
        server_key = client.get_transport().get_remote_server_key()
        got = server_key.get_name() + " " + server_key.get_base64()
        print(f"[hostkey] {got[:60]}...")
    except Exception:
        pass

    stdin, stdout, stderr = client.exec_command(cmd, timeout=900)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    rc = stdout.channel.recv_exit_status()

    if out:
        print(out)
    if err:
        print("[STDERR]", err)
    print(f"[EXIT] {rc}")
    client.close()
    sys.exit(rc)

