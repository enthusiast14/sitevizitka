import argparse
import os
import socket

from app import create_app


app = create_app()


def get_local_ip():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect(("8.8.8.8", 80))
        return sock.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        sock.close()


def parse_args():
    parser = argparse.ArgumentParser(
        description="Запуск Flask-приложения на указанном IP-адресе и порту."
    )
    parser.add_argument(
        "--host",
        default=os.getenv("HOST", get_local_ip()),
        help="IP-адрес для запуска. По умолчанию используется локальный адрес ПК.",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.getenv("PORT", "5000")),
        help="Порт для запуска. По умолчанию 5000.",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        default=os.getenv("FLASK_DEBUG", "1") == "1",
        help="Включить debug-режим.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    bind_url = f"http://{args.host}:{args.port}"

    print(f"Приложение запускается по адресу: {bind_url}")
    if args.host != "127.0.0.1":
        print("Если устройства находятся в одной сети, они могут открывать этот адрес напрямую.")

    app.run(host=args.host, port=args.port, debug=args.debug)
