# Passo a passo: do zero ao GitHub

Tempo estimado: 3 a 5 horas na primeira vez. Custo esperado: perto de zero (o dataset todo tem poucos GB e o plano gratuito do BigQuery dá 1 TB de consulta por mês).

## 0. Pré-requisitos
- Conta Google com um projeto no Google Cloud (o modo sandbox, sem cartão, funciona; as tabelas expiram em 60 dias, então refaça o `dbt build` se precisar). Por isso as tabelas silver não são particionadas: no sandbox, partições com datas antigas expiram na hora e a tabela fica vazia. Por isso as tabelas silver não são particionadas: no sandbox, partições com datas antigas expiram na hora e a tabela fica vazia. Por isso as tabelas silver não são particionadas: no sandbox, partições com datas antigas expiram na hora e a tabela fica vazia.
- `gcloud` CLI (inclui o comando `bq`), Python 3.10+, `git` e conta no GitHub.

## 1. Preparar o Google Cloud
```bash
gcloud auth login
gcloud auth application-default login      # usado pelo dbt (method: oauth)
gcloud config set project SEU_PROJECT_ID
```
Importante: o dataset público fica na região **US**. Os seus datasets também precisam ficar em US (o `profiles.yml.example` já está configurado).

## 2. Ambiente Python e dbt
```bash
cd ga4-bigquery-portfolio
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
mkdir -p ~/.dbt && cp profiles.yml.example ~/.dbt/profiles.yml
# edite ~/.dbt/profiles.yml e troque YOUR_GCP_PROJECT_ID
dbt debug        # tudo precisa estar "OK"
dbt deps         # instala o dbt_utils
```
O `maximum_bytes_billed` do profile (20 GB) é um freio de segurança: consultas acima disso falham em vez de cobrar.

## 3. Exploração (a sua parte de analista)
Rode com **dry run primeiro**:
```bash
./scripts/dry_run.sh sql/exploration/01_event_counts.sql
./scripts/run_query.sh sql/exploration/01_event_counts.sql    # salva CSV em docs/results/
```
Ordem sugerida e o que registrar no README:

| Arquivo | Pergunta | Registre |
|---|---|---|
| `01_event_counts.sql` | Quantos eventos de cada tipo? | Total (deve dar 4.295.584) |
| `02_event_params_keys_coverage.sql` | Quais chaves existem e qual a cobertura? | Chaves universais vs condicionais |
| `03_flat_events_validation.sql` | Achatar sem multiplicar linhas? | `counts_match = true` |
| `04_nulls_by_event.sql` | Onde faltam `ga_session_id` e `page_location`? | Eventos com nulos |
| `05_repeated_keys_per_event.sql` | Alguma chave se repete no mesmo evento? | Resultado vazio = seguro |
| `06_date_vs_timestamp_timezone.sql` | Qual fuso explica `event_date`? | Fuso com ~0% de divergência |
| `07_items_unnest_pitfall.sql` | Quanto o `UNNEST(items)` infla a contagem? | Tabela de inflação (print!) |
| `08_search_event_params.sql` | A chave de busca é mesmo `search_term`? | Nome da chave |

Se o `08` mostrar outro nome para o termo de busca, ajuste `search_term` em `models/staging/stg_ga4__events.sql` (linha com `ga4_param('search_term', ...)`). Se o `06` mostrar outro fuso com divergência menor, troque `timezone` em `dbt_project.yml`.

## 4. Construir o pipeline
Primeiro com 1 mês (barato e rápido):
```bash
dbt build --vars '{"start_date": "20210101", "end_date": "20210131"}'
```
Se passou, o período completo:
```bash
dbt build
```
Isso cria `ga4_portfolio_silver` (staging + sessões) e `ga4_portfolio_gold` (marts), e roda todos os testes. Se algum teste falhar, **não esconda**: investigue e documente em `docs/achados.md`. Um teste que falhou e foi explicado vale mais no portfólio do que um pipeline sem testes.

Se algum modelo falhar por coluna inexistente (por exemplo em `ecommerce.*`), confira o schema no console do BigQuery e ajuste o `select` do `stg_ga4__events.sql`.

## 5. Documentação e lineage
```bash
dbt docs generate && dbt docs serve
```
Tire um print do grafo de lineage (bronze → silver → gold) e salve em `docs/img/lineage.png`.

## 6. Gráficos para o README
```bash
pip install -r requirements-extra.txt
export GCP_PROJECT=SEU_PROJECT_ID
python scripts/make_charts.py        # gera docs/img/funnel.png e step_duration.png
```

## 7. Dashboard (Looker Studio, gratuito)
1. Acesse lookerstudio.google.com, **Criar > Relatório > BigQuery**.
2. Conecte `SEU_PROJECT_ID > ga4_portfolio_gold`.
3. Páginas sugeridas:
   - **Funil:** `fct_funnel_overall` (barras por `step`) e `fct_funnel_daily` (série diária de `closed_purchase`, filtro por `device_category`).
   - **Tempo por etapa:** `fct_step_duration` (mediana e p90 por `step`).
   - **Busca:** `fct_search_conversion` (taxa de compra com e sem busca; calcule `purchase_sessions / sessions` em campo calculado) e `fct_search_terms` (top termos).
   - **Qualidade de dados:** `dq_events_daily` (nulos e colisões por evento).
4. Compartilhe como "qualquer pessoa com o link pode ver" e coloque o link no README.

## 8. Preencher os achados
Copie `docs/achados_template.md` para `docs/achados.md` e preencha com os **seus** números (os CSVs de `docs/results/` e as tabelas do gold). Depois atualize a seção "Key findings" do `README.md`. Não deixe nenhum `TODO` no que for publicar.

## 9. Publicar no GitHub
```bash
git init
git add .
git commit -m "GA4 e-commerce analytics: dbt + BigQuery"
# opção A: GitHub CLI
gh repo create ga4-bigquery-portfolio --public --source=. --push
# opção B: crie o repo vazio no site e depois
# git remote add origin git@github.com:SEU_USUARIO/ga4-bigquery-portfolio.git
# git push -u origin main
```
Antes do `push`, confira:
- [ ] `git status` não mostra `profiles.yml`, `target/`, `logs/` nem chaves `.json` (o `.gitignore` já cobre).
- [ ] Nenhum PROJECT_ID privado em arquivos versionados (o repo usa só placeholders).
- [ ] README sem `TODO`, com prints, link do dashboard e números reais.
- [ ] Adicione os *topics* no GitHub: `dbt`, `bigquery`, `ga4`, `data-engineering`, `analytics-engineering`.

## 10. Como contar isso em entrevista
1. **Problema:** dados de eventos tagueados trazem armadilhas de granularidade (`UNNEST`, joins) que fazem números "do mesmo evento" divergirem.
2. **O que você construiu:** pipeline em camadas, sessionização própria, funil, busca, retenção e um scorecard de qualidade.
3. **Decisões:** chave de evento sem colisão, funil aberto vs fechado, fuso horário, custo (partição, cluster, dry run, teto de bytes).
4. **O que você descobriu:** os seus números reais, incluindo o que deu errado.

Dica final: pegue o que você aprendeu na investigação Datadog vs Power BI e transforme em um parágrafo "Lessons learned" no README. É esse parágrafo que diferencia um projeto de portfólio de um tutorial.
