-- Consulta 3 - Fraudes

WITH Historico_Cliente AS (
    -- 1. Calcula o total de reembolsos e o valor total por cliente e por motivo
    SELECT 
        pag.idCliente,
        m.motivo AS motivo_reembolso,
        COUNT(r.id_reembolso) AS qtd_reembolsos_cliente,
        SUM(r.valor_reemb) AS valor_total_reembolsado
    FROM Reembolso r
    JOIN motivo m ON r.idmotivo = m.id_motivo
    JOIN Nota_Fiscal nf ON r.idNota_Fiscal = nf.id_nota_fiscal
    JOIN Pagamento pag ON nf.id_nota_fiscal = pag.idNota_Fiscal
    GROUP BY pag.idCliente, m.motivo
),
Estatisticas_Plataforma AS (
    -- 2. Calcula a média e o desvio padrão de reembolsos por motivo na plataforma inteira
    SELECT 
        motivo_reembolso,
        AVG(qtd_reembolsos_cliente) AS media_qtd_plataforma,
        AVG(valor_total_reembolsado) AS media_valor_plataforma,
        STDDEV(qtd_reembolsos_cliente) AS desvio_padrao_qtd
    FROM Historico_Cliente
    GROUP BY motivo_reembolso
)

-- 3. Cruzamento final: Encontrando os possíveis fraudadores usando Z-Score
SELECT 
    hc.idCliente,
    hc.motivo_reembolso,
    
    -- Histórico do Cliente
    hc.qtd_reembolsos_cliente,
    hc.valor_total_reembolsado,
    
    -- Comparação com a Plataforma
    ep.media_qtd_plataforma,
    ep.media_valor_plataforma,
    
    -- Cálculo do Z-Score (Diferença entre o cliente e a média, dividida pelo desvio padrão)
    -- Usando NULLIF para evitar erro de divisão por zero caso o desvio padrão seja 0
    (hc.qtd_reembolsos_cliente - ep.media_qtd_plataforma) / NULLIF(ep.desvio_padrao_qtd, 0) AS z_score_fraude

FROM Historico_Cliente hc
JOIN Estatisticas_Plataforma ep ON hc.motivo_reembolso = ep.motivo_reembolso

-- Filtro Estatístico: Só traz clientes que tenham um Z-Score maior que 2 (Anomalia/Fraude)
WHERE (hc.qtd_reembolsos_cliente - ep.media_qtd_plataforma) / NULLIF(ep.desvio_padrao_qtd, 0) > 2

ORDER BY z_score_fraude DESC;