# Sensor + Smartwatch Mini Project

지금까지 만든 모듈(시계, 스톱워치, UART, FIFO, 센서 컨트롤러)을 하나의 Top으로 통합한 미니 프로젝트입니다.
버튼과 **UART 문자열 명령** 둘 다로 제어하고, 결과를 FND와 UART로 출력합니다.

📄 보고서: [docs/project sensor_stopwatch_uart_fifo_version2.pdf](docs)

## 구성

```
            ┌──────────── uart_fifo (RX/TX + FIFO) ◀──▶ PC
            │                 │ rx_data          ▲ ascii_sender
            ▼                 ▼                  │
   btn ─▶ btn_debounce ─▶ controller ◀── ascii_decoder
                              │
         ┌────────────┬───────┴──────┬──────────────┐
      smartwatch    sr04_top      dht11_top          │
   (watch+stopwatch) (초음파 거리) (온습도)            │
         └────────────┴──────┬───────┴──────────────┘
                           o_mux ─▶ fnd_controller ─▶ FND
                             └─▶ digit_splitter ─▶ ascii_encoder ─▶ UART TX
```

| 모듈 | 역할 |
|---|---|
| `sr04_controller.v` | HC-SR04 trigger 펄스 생성, echo 폭 측정 → 거리 계산 |
| `dht11_controller.v` | DHT11 단선(`inout`) 프로토콜: start 신호 → 응답 → 40bit 수신 → checksum |
| `ascii_decoder.v` | 수신 문자를 누적해 `.`(0x2E)에서 문자열 명령 확정 → 센서 조회 / 스톱워치·시계 제어 |
| `ascii_encoder`, `digit_splitter` | 측정값을 자릿수로 나눠 ASCII로 변환해 PC로 전송 |
| `smartwatch.v` | 시계 / 스톱워치 모드 통합 |
| `uart_fifo_loopback.v`, `fifo.v`, `uart.v` | UART 송수신 버퍼링 |

## 입출력 (Basys-3)

| 신호 | 연결 |
|---|---|
| `rx`, `tx` | USB-UART |
| `trig`, `echo` | SR-04 (Pmod) |
| `dht11` | DHT11 데이터 (양방향) |
| `btnl/r/u/d`, `sw[3:0]` | 모드·편집 제어 |
| `fnd_com`, `fnd_data` | 4자리 7-segment |

## 파일

- `2026_0814_miniproject.xpr` — Vivado 프로젝트
- `sim_1/new/tb_miniproject.v`, `tb_ascii_decoder.v` — 통합 / 명령 디코더 테스트벤치
