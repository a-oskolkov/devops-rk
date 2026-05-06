# syntax=docker/dockerfile:1 #директива синтаксиса для docker buildkit

# на этом этапе собирается изолированное prod окружение
# позволяет не переносить в финальный образ кэш pip, build инструменты и dev зависимости
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv

WORKDIR /build

RUN python -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY app/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt


# Финальный образ содержит только runtime-зависимости и код приложения
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /srv

# Non-root пользователь снижает риск: даже при компрометации приложения процесс
# не получает root-права внутри контейнера.
RUN addgroup --system appgroup \
    && adduser --system --ingroup appgroup --home /srv appuser

COPY --from=builder /opt/venv /opt/venv
COPY app ./app

RUN chown -R appuser:appgroup /srv /opt/venv

USER appuser

EXPOSE 5000

# хэлсчек для автоматической проверки, что контейнер действительно отвечает после сборки и запуска.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=2).read()"

# gunicorn вместо встроенного flask dev сервера, потому что это
# prod сервер, подходящий для контейнерного запуска
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
