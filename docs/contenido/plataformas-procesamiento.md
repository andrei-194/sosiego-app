# Plataformas para delegar el procesamiento de contenido de Sosiego

Fecha del estudio: 2026-11-06. Investigación documental: no se creó ninguna cuenta, no se gastó dinero ni se descargó ningún modelo.

Convención de fuentes: **[V]** = leído hoy en la página oficial del proveedor; **[T]** = solo en agregadores o buscadores de terceros (puede estar desfasado); **[E]** = estimación mía (cálculo o juicio, no medido); **[NV]** = no pude verificarlo.

## 1. Qué hay que procesar (volumen real estimado)

Leído de `tools/content_pipeline/pipeline/{tag,moments,reflections,editorial,ollama_client}.py` y del README. Los tokens son **estimaciones [E]** (español ≈ 3,5 caracteres por token); conviene medirlos en el piloto con el campo `usage` de cada API.

| Etapa | Llamadas | Entrada por llamada | Salida por llamada | Entrada total | Salida total |
| --- | --- | --- | --- | --- | --- |
| Etiquetado (`tag`): 31.084 versículos, lista cerrada de 15 temas + `card_score` | 31.084 (+5 % de reintentos) | ≈ 600 tok (sistema ≈ 50, lista de temas e instrucciones ≈ 450, versículo ≈ 50, esquema JSON ≈ 50) | ≈ 70 tok | ≈ 19,6 M | ≈ 2,3 M |
| Parecidos (`similar`): embeddings BGE-M3, no es un LLM generativo | n/a | ≈ 50 tok por versículo | n/a | ≈ 1,6 M (embeddings) | n/a |
| Momentos (`moments candidates`): 12 llamadas con 60 candidatos cada una | 12 (+reintentos) | ≈ 4.500 tok | ≈ 150 tok | ≈ 0,1 M | ≈ 0,005 M |
| Reflexiones (`reflections generate`): 685 plazas; la guía editorial va en el prompt de sistema | 685 × 1,3 intentos | ≈ 1.100 tok (guía ≈ 600, instrucciones y versículo ≈ 500) + contexto del reintento | ≈ 300 tok (JSON de cuatro bloques, 90-150 palabras) | ≈ 1,05 M | ≈ 0,27 M |
| Reflexiones, variante con **3 borradores por plaza** (para elegir el mejor al revisar) | 2.055 × 1,3 | igual | igual | ≈ 3,2 M | ≈ 0,85 M |

**Escenario A** (un borrador por reflexión): ≈ **20,8 M tokens de entrada y 2,6 M de salida**.
**Escenario B** (tres borradores por reflexión): ≈ **22,9 M de entrada y 3,2 M de salida**.

Observaciones que cambian la decisión:

- Casi todo el volumen es el etiquetado (94 % de la entrada). Es una tarea de clasificación simple: un modelo barato basta. Las 685 reflexiones son pocas (≈ 1 M de tokens), así que **ahí conviene pagar por calidad**: la diferencia entre un modelo barato y uno bueno son pocos dólares.
- El prefijo común del etiquetado (≈ 500 de 600 tokens) es cacheable si se reordena el prompt dejando el versículo al final. Con modelos pequeños el mínimo cacheable puede impedirlo [NV: no encontré el mínimo cacheable de Haiku 5.5 en la página de precios], así que **no cuento con caché** en las cuentas (es un margen a favor).
- Los modelos con "razonamiento" (Gemini 3.x Flash, GPT-5.x, DeepSeek) cobran los tokens de pensamiento como salida. Hay que desactivar o minimizar el razonamiento; si no, la salida puede multiplicarse por 3-10 y las cuentas de abajo se quedan cortas.
- `similar` no necesita un LLM: BGE-M3 sobre 31 mil textos cortos corre en CPU local o en una GPU gratis (Kaggle) en minutos u horas [E]. Si se prefiere API, DeepInfra lista embeddings a $0,005-0,01 por millón de tokens [V, 2026-11-06, deepinfra.com/pricing]: unos $0,02 en total, pero **no verifiqué que BGE-M3 esté disponible ahí**.
- `moments` es trivial (12 llamadas); la elección real es humana.

## 2. Precios verificados (todas las cifras en USD por millón de tokens, salvo indicación)

### APIs propietarias con Batch

| Modelo | Normal entrada / salida | Batch entrada / salida | Fuente y fecha |
| --- | --- | --- | --- |
| Claude Haiku 5.5 (prompts hasta 100 k tokens) | 0,10 / 0,50 (lectura de caché 0,01) | **0,05 / 0,25** | [V] platform.claude.com/docs/en/about-claude/pricing, 2026-11-06 |
| Claude Sonnet 5.5 | 2 / 10 (caché 0,10) | **1 / 5** | [V] misma página, 2026-11-06 |
| Claude Opus 5.5 | 4 / 20 | 2 / 10 | [V] misma página |
| Claude Haiku 4.5 (anterior) | 1 / 5 | 0,50 / 2,50 | [V] misma página |
| Gemini 3.1 Flash-Lite | 0,25 / 1,50 | **0,125 / 0,75** | [V] aistudio.google.com/docs/pricing (redirige desde ai.google.dev), 2026-11-06 |
| Gemini 3.5 Flash-Lite | 0,30 / 2,50 | 0,15 / 1,25 | [V] misma página |
| Gemini 3.6 Flash y 3.8 Flash | 0,75 / 3,75 hasta 31-dic-2026; **desde 2027-01-01 sube a 1,50 / 7,50** | 0,375 / 1,875 (desde 2027: 0,75 / 3,75) | [V] misma página |
| Gemini 3.1 Pro (preview) | 2 / 12 (≤ 200 k) | 1 / 6 | [V] misma página |
| OpenAI gpt-5-nano | 0,05 / 0,40 | 0,025 / 0,20 | [V] developers.openai.com/api/docs/pricing, 2026-11-06 |
| OpenAI gpt-5.4-nano | 0,20 / 1,25 | 0,10 / 0,625 | [V] misma página |
| OpenAI gpt-5-mini | 0,25 / 2,00 | 0,125 / 1,00 | [V] misma página |
| OpenAI gpt-5.4-mini | 0,75 / 4,50 | 0,375 / 2,25 | [V] misma página |

Batch de Anthropic: descuento del 50 % en entrada y salida, se combina con la caché de prompts; la mayoría de lotes termina en menos de 1 hora, expira a las 24 h; soporta salidas estructuradas con el mismo 50 % [V, páginas de batch-processing y structured-outputs, 2026-11-06]. **Importante:** el lote de Anthropic no es apto para retención cero (retiene 29 días) [V]. Para este proyecto no importa: la entrada es la Biblia de dominio público y no hay datos de usuarios. Límites de tamaño por lote (recuerdo 100.000 solicitudes / 256 MB) [NV en esta sesión].

Salidas estructuradas de Anthropic: **no admiten `minimum`, `maximum`, `minLength`, `maxLength` ni `minItems` mayor que 1** (devuelven error 400) [V]. El esquema actual del pipeline usa `minimum`/`maximum` (`weight`, `card_score`), `maxItems` y `minLength` → hay que quitarlos del esquema enviado y dejar que el validador local (`jsonschema`, que ya existe) los compruebe. Gemini y OpenAI tienen restricciones parecidas en parte [NV].

Gemini: la página dice que el nivel gratuito existe para Flash y Flash-Lite pero **no tiene batch** [V]. Que en el nivel gratis Google use los datos para mejorar sus productos es lo que recuerdo de sus términos [NV hoy]; no importa con texto público, pero evita depender del nivel gratis por límites diarios [NV: no leí las cifras].

### APIs de modelos abiertos

| Proveedor / modelo | Entrada / salida | Batch | Fuente y fecha |
| --- | --- | --- | --- |
| DeepSeek `deepseek-flash` (V4.1 Flash) | valle: 0,15 / 0,60; punta: 0,30 / 1,20; caché acierto 0,003-0,006 | no vi API batch; el descuento es el horario valle (50 %: sábados, domingos y fuera de 01-04 y 06-10 UTC lun-vie) | [V] api-docs.deepseek.com/quick_start/pricing/, 2026-11-06 |
| DeepSeek `deepseek-v4-pro` | valle: 0,66 / 1,98; punta: 1,32 / 3,96 | igual | [V] misma página |
| Together: Qwen3.8 Flash | 0,15 / 0,47 | la página tiene columna "Batch API price" sin cifras; el 50 % es [NV] | [V] together.ai/pricing, 2026-11-06 |
| Together: Qwen2.5 7B Instruct Turbo | 0,30 / 0,30 | [NV] | [V] misma página |
| Together: Qwen3.5 9B | 0,17 / 0,25 | [NV] | [V] misma página |
| Together: DeepSeek V4.1 Flash | 0,30 / 1,20 | [NV] | [V] misma página |
| Together GPU dedicada | H100 $5,49/h; B200 $8,99/h | | [V] misma página |
| Fireworks: DeepSeek V4.1 Flash | 0,30 / 1,20 | **50 % de descuento en batch** | [V] fireworks.ai/pricing, 2026-11-06 |
| Fireworks GPU a demanda | H100 $8/h; H200 $8/h; B200 $13/h | | [V] misma página |
| DeepInfra: Llama-3.3-70B | 0,10 / 0,32 | nivel "Flex" = 0,8 × el precio | [V] deepinfra.com/pricing, 2026-11-06 |
| DeepInfra: Qwen3-32B | 0,08 / 0,28 | Flex 0,8 × | [V] misma página |
| DeepInfra: DeepSeek-V3.2 | 0,26 / 0,38 | Flex 0,8 × | [V] misma página |
| DeepInfra GPU dedicada | A100 $1,49/h; H100 $2,90/h; H200 $3,49/h | | [V] misma página |
| Groq: gpt-oss-120b / gpt-oss-20b | 0,15 / 0,60 y 0,075 / 0,30 | 50 % [T] | [T] morphllm.com/groq-pricing (octubre 2026); groq.com/pricing no mostró precios |
| Groq: Llama 3.3 70B | 0,59 / 0,79 | 50 % [T] | [T] aipricing.guru (junio 2026) |
| Mistral Large | 0,5 / 1,5 | 50 % | [V] mistral.ai/pricing, 2026-11-06 (Small y Medium: [NV]) |
| OpenRouter | precio de lista del proveedor, sin recargo por solicitud; **5,5 % al comprar créditos**; modelos gratis: 20 solicitudes/min y 50/día (1.000/día con ≥ $10 de créditos); no entrena con datos y ofrece ruta de retención cero | n/a | [V] openrouter.ai/pricing, 2026-11-06 |

Límites de uso: DeepInfra 200 solicitudes concurrentes por cuenta [V]; DeepSeek concurrencia 2.500 (flash) y 500 (pro) [V]; Groq limita por solicitudes/tokens por minuto y por día, y no pude leer las cifras por plan [NV]. Con 31 mil llamadas cortas, 50-200 solicitudes concurrentes bastan para terminar en 1-3 horas.

### GPU alquilada

| Proveedor | GPU y precio por hora | Fuente y fecha |
| --- | --- | --- |
| RunPod pods | Community / Secure: RTX 4090 24 GB $0,34 / $0,89; RTX 5090 32 GB $0,69 / $1,19; L40S 48 GB $0,79 / $1,09; A40 48 GB $0,35 / $0,59; A100 80 GB PCIe $1,19 / $1,79; H100 PCIe $1,99 / $2,89; H100 SXM $2,69 / $3,99; H200 $3,59 / $5,29. Facturación por segundo | [V] runpod.io/pricing, 2026-11-06 |
| Lambda | A10 24 GB $1,29; A100 $1,99-3,19; H100 $3,79-4,89; B200 $7,69-7,99. **Precios válidos desde 2026-11-16** (hasta entonces, los de la cuenta) | [V] lambda.com/pricing, 2026-11-06 |
| Vast.ai (mercado, precios por anfitrión, muchos interrumpibles) | RTX 4090 desde ≈ $0,14-0,36; A100 desde ≈ $0,34-0,74 (a veces $1,50+); H100 ≈ $1,79-2,14 | [T] activepieces.com, hostinger.com, deploybase.ai (agosto-septiembre 2026). No pude abrir la página oficial de Vast |
| Colab Pro | $9,99/mes, 100 unidades de cómputo; una T4 gasta ≈ 1,2-1,8 unidades/h → ≈ 55-80 h de T4 por compra. Google no publica los límites de GPU | [T] resultados de búsqueda (marzo-2026 y anteriores); [NV] página oficial |
| Kaggle gratis | ≈ 30 h de GPU por semana (P100 o 2 × T4), sesiones de 12 h; la cuota "flota" | [T]; [NV] oficial |

Throughput de vLLM (**todo [E], no medido**): Qwen2.5-7B en una RTX 4090 con concurrencia alta ≈ 2.500-3.500 tok/s de salida y ≈ 15-25 k tok/s de prellenado; un modelo de 32 B cuantizado (AWQ) en A100 80 GB ≈ 1.000-1.500 tok/s de salida y ≈ 6-8 k tok/s de prellenado; 70 B en H100 ≈ 600-1.000 tok/s.

## 3. Cuentas de costo para el proyecto

Cálculo: `entrada_M × precio_entrada + salida_M × precio_salida`. A = 20,8 M entrada y 2,6 M salida (un borrador). B = 22,9 M entrada y 3,2 M salida (tres borradores). Sin caché, sin tokens de razonamiento.

| Opción | Cuenta (escenario A) | A | B |
| --- | --- | --- | --- |
| **Haiku 5.5 Batch para todo** | 20,8 × 0,05 + 2,6 × 0,25 = 1,04 + 0,65 | **$1,7** | $2,0 |
| Haiku 5.5 normal | 20,8 × 0,10 + 2,6 × 0,50 | $3,4 | $3,9 |
| **Sonnet 5.5 Batch para todo** | 20,8 × 1 + 2,6 × 5 = 20,8 + 13 | **$33,8** | $38,9 |
| Sonnet 5.5 normal | doble | $67,6 | $77,8 |
| **Híbrido Anthropic Batch: Haiku 5.5 en etiquetas y momentos, Sonnet 5.5 en reflexiones (B)** | etiquetas 19,7 × 0,05 + 2,3 × 0,25 = 1,56; reflexiones B 3,2 × 1 + 0,85 × 5 = 7,45 | — | **≈ $9,0** |
| Gemini 3.1 Flash-Lite Batch | 20,8 × 0,125 + 2,6 × 0,75 = 2,6 + 1,95 | $4,6 | $5,3 |
| Gemini 3.5 Flash-Lite Batch | 20,8 × 0,15 + 2,6 × 1,25 | $6,4 | $7,4 |
| Gemini 3.6 Flash Batch (hasta 31-dic-2026) | 20,8 × 0,375 + 2,6 × 1,875 | $12,7 | $14,6 |
| Híbrido Gemini: Flash-Lite 3.1 Batch en etiquetas + 3.6 Flash Batch en reflexiones (B) | 4,2 + 2,8 | — | **≈ $7** (≈ $8,5 si se hace en 2027) |
| OpenAI gpt-5-nano Batch (con razonamiento mínimo) | 20,8 × 0,025 + 2,6 × 0,20 | $1,0 | $1,1 |
| OpenAI gpt-5.4-nano Batch | 20,8 × 0,10 + 2,6 × 0,625 | $3,7 | $4,3 |
| OpenAI gpt-5.4-mini Batch | 20,8 × 0,375 + 2,6 × 2,25 | $13,7 | $15,8 |
| DeepSeek flash, horario valle | 20,8 × 0,15 + 2,6 × 0,60 | $4,7 (con caché de prefijo ≈ $3) | $5,3 |
| DeepSeek v4-pro, horario valle | 20,8 × 0,66 + 2,6 × 1,98 | $18,9 | $21,5 |
| DeepInfra Qwen3-32B | 20,8 × 0,08 + 2,6 × 0,28 | **$2,4** (Flex × 0,8 ≈ $1,9) | $2,8 |
| DeepInfra Llama-3.3-70B | 20,8 × 0,10 + 2,6 × 0,32 | $2,9 | $3,4 |
| Together Qwen3.8 Flash | 20,8 × 0,15 + 2,6 × 0,47 | $4,3 | $4,9 |
| Together Qwen2.5 7B Turbo | 20,8 × 0,30 + 2,6 × 0,30 | $7,0 | $7,8 |
| Fireworks DeepSeek V4.1 Flash, batch | (20,8 × 0,30 + 2,6 × 1,20) × 0,5 | $4,7 | $5,3 |
| Groq gpt-oss-120b [T] | 20,8 × 0,15 + 2,6 × 0,60 | $4,7 (batch ≈ $2,3) | $5,3 |
| Groq Llama 3.3 70B [T] | 20,8 × 0,59 + 2,6 × 0,79 | $14,3 | $16,4 |
| Mistral Large batch | (20,8 × 0,5 + 2,6 × 1,5) × 0,5 | $7,2 | $8,2 |
| OpenRouter | precio del proveedor + 5,5 % | ≈ +5,5 % | ≈ +5,5 % |

GPU alquilada con vLLM (tiempos [E], sin medir):

| Modelo | GPU | Tiempo de cómputo estimado (etiquetas + reflexiones) | Costo del cómputo | Costo realista con instalación, pruebas y reintentos (× 3-4) |
| --- | --- | --- | --- | --- |
| Qwen2.5-7B (el actual) | RTX 4090 Community $0,34/h | 1-1,5 h | $0,4-0,5 | **$1-2** |
| Qwen 32 B-AWQ (familia Qwen3/2.5) | A100 80 GB Community $1,19-1,39/h | ≈ 2 h | $2,4-2,8 | **$8-12** |
| Llama 3.3 70B-AWQ | H100 PCIe $1,99/h | ≈ 3-4 h | $6-8 | **$15-25** |
| Kaggle (2 × T4) / Colab Pro | gratis / $9,99 | 3-8 h dentro de la cuota | $0 / $9,99 | $0 / $9,99 (sesiones de 12 h; el pipeline es reanudable) |

Comparación con el estado actual: la CPU local necesita ≈ 122 h solo para etiquetar; casi cualquier opción de arriba lo hace en menos de 3 horas por menos de $35.

## 4. Tabla comparativa cualitativa

Calidad: **[E] juicio mío, sin benchmark propio**. La única medición real es la de Qwen2.5-7B en CPU (README: 23,9 % pasa validadores a la primera, 91,3 % con reintentos). Se debe medir en el piloto (sección 7).

| Opción | Español natural y tono cuidadoso | JSON estricto | Límites | Privacidad y licencia de salidas | Integración con el pipeline |
| --- | --- | --- | --- | --- | --- |
| Anthropic Haiku 5.5 / Sonnet 5.5 Batch | Muy bueno (Sonnet) a bueno (Haiku); Sonnet es mi favorito para texto sensible [E] | Salida estructurada soportada, también en batch [V]; hay que quitar `minimum`/`maximum`/`minLength` del esquema | Lotes asíncronos (< 1 h típico, máx. 24 h); límites de tamaño [NV] | Lote con retención de 29 días [V]; los términos comerciales de Anthropic dan la propiedad de las salidas al cliente [NV hoy, confirmar en términos]; cumple lo que exige el spec §11 (licencia comercial de las salidas) | Hay que escribir un ejecutor por lotes (ver §6). El transporte síncrono sirve para el piloto |
| Gemini 3.1 Flash-Lite / 3.x Flash Batch | Bueno a muy bueno en español [E]; Flash-Lite algo plano | Esquema JSON soportado [NV detalles en batch] | Batch 24 h; el nivel gratis no tiene batch [V] | De pago: no entrena con los datos (recuerdo) [NV]; salidas del cliente [NV] | Ejecutor por lotes propio; API distinta |
| OpenAI gpt-5.4-nano/mini, gpt-5-nano Batch | Bueno; mini mejor que nano [E] | `json_schema` estricto, muy fiable [E] | Batch 24 h | Salidas del cliente por términos de OpenAI [NV hoy] | Ejecutor por lotes (formato JSONL); el endpoint síncrono es compatible con OpenAI |
| DeepSeek flash / v4-pro | Bueno en español, a veces con giros neutros-latinos o calcos [E] | `JSON Output: Yes` [V] | Concurrencia 2.500 / 500 [V]; sin batch visto | Servidores en China, sin retención cero conocida [NV]; texto público, riesgo bajo. Modelo de licencia abierta [NV] | **Muy fácil**: API compatible con OpenAI y con Anthropic [V] |
| Together / DeepInfra / Fireworks (Qwen3-32B, Llama 3.3 70B, DeepSeek) | Bueno con 32 B+ (Qwen3, Llama 3.3); Qwen 7B es flojo en prosa (medido) | Depende del modelo; vLLM/Fireworks/Together soportan `response_format` con JSON Schema; reintentos ya cubiertos por el pipeline | DeepInfra 200 concurrentes [V] | Cada proveedor declara retención distinta [NV]. Licencias: Qwen2.5 7B/32B Apache-2.0 y Mistral Small 3 Apache-2.0; Llama 3.3 con licencia comunitaria (atribución "Built with Llama") y Gemma con sus términos de uso — todas permiten usar las salidas comercialmente según lo que recuerdo [NV, confirmar] | **Fácil**: API compatible con OpenAI (un adaptador de `transport`) |
| Groq | Llama 70B/gpt-oss: aceptable; gpt-oss es más débil en español literario [E] | JSON soportado [NV] | Límites por minuto y por día estrictos [NV cifras] | Retención [NV] | Fácil (compatible con OpenAI) |
| OpenRouter | Depende del modelo; útil para comparar candidatos con una sola clave | Depende | +5,5 % en créditos; modelos gratis 50/día [V] | No entrena; retención cero configurable [V] | **Muy fácil** y ideal para el piloto (un adaptador, muchos modelos) |
| Mistral (Large batch) | Muy bueno en español (empresa europea) [E] | Soporte de JSON [NV] | | | Compatible con OpenAI [NV] |
| RunPod / Vast / Lambda + vLLM | El que elijas: con Qwen 32 B o Llama 70 B, bueno; con 7 B, flojo | vLLM con `guided_json`/`response_format`: JSON válido garantizado | Ninguno salvo disponibilidad; Vast puede interrumpir | **Máxima**: nada sale de tu instancia. Licencia del modelo, la que declares arriba | **Muy fácil**: vLLM expone una API de OpenAI; basta apuntar el adaptador. Cambia solo `host` y el formato de `format` |
| Kaggle / Colab Pro | Igual que arriba, limitado a modelos que quepan en T4 (16 GB): 7-14 B en AWQ | vLLM | Cuota semanal y sesiones de 12 h; Colab no publica límites | Tus datos en Google/Kaggle | Más manual: túnel (ngrok/cloudflared) o ejecutar el pipeline dentro del cuaderno |

## 5. Recomendación

**Principal: Anthropic Message Batches, híbrido.**
- Etiquetado y momentos: Claude Haiku 5.5 en Batch ($0,05 / $0,25): ≈ $1,6 por las 31.084 etiquetas.
- Reflexiones: Claude Sonnet 5.5 en Batch ($1 / $5), con 3 borradores por plaza para que la revisión humana elija: ≈ $7,5.
- **Total ≈ $9 (rango $4-15)**; con todo en Sonnet 5.5 ≈ $34-39. La decisión pesa poco en dinero y mucho en calidad del borrador, por eso se paga Sonnet donde hay texto sensible.
- Razones: mejor español y tono de las opciones evaluadas [E], salida estructurada también en batch [V], el spec §11 exige confirmar licencia comercial de las salidas (términos comerciales claros), y el lote termina en horas en lugar de días de CPU.
- Contra: ejecutor por lotes nuevo (ver §6), y el esquema debe aligerarse (sin `minimum`, `maximum`, `minLength`).

**Plan B: Gemini en Batch** (3.1 Flash-Lite para etiquetas, 3.6 Flash para reflexiones): ≈ $7 hoy; **los Flash 3.6/3.8 duplican su precio el 2027-01-01** (hacerlo antes si se elige). Alternativa casi equivalente y sin vendor lock-in: **Qwen3-32B o Llama 3.3 70B en DeepInfra** (≈ $2-3 en total, compatible con OpenAI, 200 concurrentes) para etiquetas, y reflexiones con Sonnet o Gemini.

**Plan C (independencia y uso futuro): GPU alquilada con vLLM**, RunPod Community con A100 80 GB ($1,19-1,39/h) y un modelo de 32 B (Qwen) o Llama 3.3 70B en una H100: de $8 a $25 todo incluido, o $0 en Kaggle si hay paciencia. Sirve si más adelante hay que regenerar contenido muchas veces (cada versión del contenido) o si se quiere que ningún texto salga a un tercero.

Descartadas: Groq y OpenRouter gratis (límites diarios incompatibles con 31 mil llamadas), Opus 5.5/Fable (calidad innecesaria para etiquetas), DeepSeek v4-pro (más caro que Haiku/Gemini sin ventaja clara en español), Vast.ai como primera opción (precios variables, interrupciones, no verificables).

## 6. Integración con el pipeline actual

- `ollama_client.chat_json(...)` ya acepta `transport(host, payload, timeout) -> str` inyectable (usado en las pruebas). El `payload` es el formato de Ollama (`messages`, `format` con el esquema, `options.temperature/seed/num_predict`). Un archivo nuevo, p. ej. `pipeline/openai_transport.py`, que traduzca ese payload a `POST /v1/chat/completions` con `response_format: json_schema` y devuelva el texto, **sirve sin cambiar las etapas** para DeepSeek, DeepInfra, Together, Fireworks, Groq, OpenRouter, Mistral y vLLM (RunPod/Vast/Lambda/Kaggle). Esfuerzo estimado: ≈ 60-100 líneas y sus pruebas (con `transport` falso, como las 239 pruebas actuales).
- El reintento con retroalimentación (`chat_json`) ya hace lo que hace falta con APIs síncronas; todo sigue pasando por `jsonschema` y `editorial.validate_reflection`, así que **la barrera de calidad no cambia con el proveedor**. `work.db` ya guarda modelo, prompt, temperatura y semilla por generación; faltaría registrar tokens y costo reales (`usage`) para cerrar las cuentas.
- Un backend por lotes (Anthropic, Gemini, OpenAI) **no cabe en `transport`**: es asíncrono. Hay que añadir un subcomando por etapa, p. ej. `batch export` (escribe el JSONL de solicitudes con un `custom_id` = id de versículo o de plaza), `batch submit/poll` y `batch import` (lee resultados, valida con los mismos validadores y guarda en `generations`). Los fallos pasan a una **segunda ronda** de batch con el error como retroalimentación (lo que hoy hace el bucle de reintentos). Esfuerzo mayor (≈ 200-300 líneas con pruebas), pero el ahorro de 50 % y el tiempo lo compensan solo para el volumen completo; para el piloto basta el modo síncrono.
- Anthropic: esquema sin `minimum`/`maximum`/`minLength` [V]; el SDK oficial (`transform_schema`) lo hace solo. Mover esas reglas a la descripción y dejar la validación local.
- Reordenar los prompts con la parte fija (lista de temas, guía editorial) **al inicio** y lo variable (versículo) **al final** habilita el caché de prefijo (Anthropic, Gemini, DeepSeek y vLLM con prefix caching) sin costo de código.
- Los parámetros `temperature 0.2` y `seed` pueden no estar disponibles en todos los modelos (algunos con razonamiento los ignoran o los rechazan) [NV]; registrar lo realmente usado.

## 7. Piloto barato (menos de $1 y una tarde)

Objetivo: medir con datos propios, para decidir sin fiarse de benchmarks ajenos.

1. **Muestra fija**: los mismos 200 versículos para todos (los 50 de la prueba de calidad actual + 150 aleatorios con la misma semilla; incluye genealogías, leyes y narración para probar `card_score`) y **40 plazas de reflexión** (20 de emoción, 10 de momento, 10 del día; con 10 temas sensibles: duelo, miedo a morir, depresión).
2. **Candidatos** (2 obligatorios + 1 opcional):
   - A: Claude Haiku 5.5 (etiquetas) y Claude Sonnet 5.5 (reflexiones), modo síncrono para que no haya espera ($2/$10 y $0,10/$0,50: esperable < $0,50 en total) [E].
   - B: un modelo abierto en DeepInfra (Qwen3-32B o Llama 3.3 70B) para ambas tareas (≈ $0,05) [E]; o Gemini 3.1 Flash-Lite / 3.6 Flash si se prefiere un segundo propietario.
   - C opcional: Qwen 32 B en RunPod (1 h de A100 ≈ $1,2-1,8) solo si el candidato B resulta bueno y se quiere probar independencia.
   - Se necesita crear 1 o 2 cuentas y cargar $5-10 de crédito: **hazlo tú; yo no lo hice**.
3. **Métricas** (guardar todo en `work.db`):
   - % JSON válido (a la primera y tras reintentos), % que pasa los validadores a la primera y tras reintentos (cifra a superar: 23,9 % / 91,3 % de qwen2.5:7b), citas ajenas, términos prohibidos, palabras fuera de rango.
   - Tokens reales de entrada y salida por llamada (contrastar con las estimaciones de §1) y **costo real por 1.000 versículos y por reflexión**; extrapolar a 31.084 y 685.
   - Etiquetas: coincidencia del tema principal contra un modelo de referencia (Sonnet 5.5 sobre los mismos 200) y contra tu lectura de 50 de ellos; distribución de `card_score` (que no sea todo 0,9).
   - Reflexiones: lectura **ciega** de 20 por candidato (orden aleatorio) con nota de 1 a 5 en: español natural, tono cuidadoso, fidelidad al versículo, sin promesas; y tiempo de revisión estimado (el spec supone 1-2 minutos por reflexión).
4. **Criterio de decisión**: pasa a la generación masiva el candidato que cumpla a la vez: ≥ 70 % de reflexiones válidas a la primera y ≥ 95 % tras reintentos; ≥ 85 % de coincidencia del tema principal con la referencia; nota media de reflexiones ≥ 4 de 5 con ninguna "peligrosa" (doctrina o consuelo dañino). Si Haiku 5.5 etiqueta igual de bien que el modelo caro, se queda con Haiku para etiquetas.
5. **Controles de gasto**: límite de gasto mensual en la consola del proveedor, un solo lote de pruebas antes de cualquier ejecución completa y verificación de que el razonamiento está apagado (revisar el campo de tokens de salida).

## 8. Riesgos

- **Precios cambian**: hay incluso un aumento programado (Gemini Flash 3.6/3.8 el 2027-01-01; Lambda el 2026-11-16). Reconfirmar la tarifa el día de lanzar el lote y fijar un tope de gasto.
- **Estimaciones de tokens**: dependen de mi cálculo por caracteres; el piloto las sustituye con medición. Una desviación de ×2 sigue dejando la opción principal en menos de $20.
- **Tokens de razonamiento**: pueden multiplicar la salida y el costo de Gemini, OpenAI y DeepSeek; apagarlos o limitarlos.
- **Calidad en texto sensible**: ningún modelo asegura teología neutral ni consuelo sin daño; la revisión del 100 % y los validadores siguen siendo la barrera. Un modelo mejor reduce el tiempo humano de edición, que es el costo real (11-23 h según el spec).
- **Salidas fuera de lista o con citas ajenas**: modelos grandes tienden a "enriquecer" con otras referencias bíblicas; el validador ya las rechaza (0 en la prueba de 7 B), pero con modelos mayores puede subir el número de reintentos: medirlo.
- **Licencias y términos**: confirmar por escrito, antes de publicar, que los términos del proveedor elegido permiten uso comercial de las salidas (spec §11). No los leí completos hoy. La licencia de los modelos abiertos (Qwen Apache-2.0 en 7B/32B; Llama con condiciones y atribución; Gemma con política de uso) está recordada de memoria [NV].
- **Retención de datos**: irrelevante para la entrada (la Biblia de dominio público), pero los borradores generados quedan en los servidores del proveedor (29 días en el batch de Anthropic [V]).
- **Cambios de modelo**: los modelos "preview" y los alias se retiran (Gemini 2.5 Flash está obsoleto desde el 2026-12-01 según la página [V]); registrar el identificador exacto del modelo en `work.db` (ya se guarda) para reproducibilidad.
- **Disponibilidad geográfica o de pago**: Anthropic, OpenAI y Google pueden exigir tarjeta y verificación; DeepSeek tiene servidores en China y picos de demanda en horario "punta".
- **Vast.ai / Colab / Kaggle**: interrupciones, cuotas variables y términos de uso; usar solo con el pipeline reanudable y no como única opción.

## 9. Qué no pude verificar

- Precios de Groq en su página oficial (solo agregadores de octubre 2026), de Mistral Small/Medium, de Vast.ai (solo agregadores) y de Colab/Kaggle (solo terceros; Google no publica límites).
- El descuento batch de Together y de Groq, y los límites por minuto/día de Groq y Gemini.
- Mínimo de tokens cacheables de Haiku 5.5 y de los límites de tamaño por lote de Anthropic, Gemini y OpenAI.
- Soporte exacto de JSON Schema en cada modelo y proveedor, y si `temperature`/`seed` se aceptan en los modelos con razonamiento.
- Términos de privacidad y propiedad de las salidas de cada proveedor (los recuerdo, no los leí hoy), y las licencias de los modelos abiertos.
- Throughput real de vLLM, tiempos y los tokens por etapa: son estimaciones mías.
- Calidad real en español: no hay benchmark propio salvo el de Qwen2.5-7B; el piloto está pensado para medirlo.
