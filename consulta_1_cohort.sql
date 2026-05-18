-- Consultas Estratégicas
-- Consulta 1 - Cohort
WITH PrimeiraCompra AS (
    -- 1. Descobrir o mês da primeira compra com base na data_pagamento
    SELECT 
        idCliente,
        MIN(DATE(data_pagamento)) AS data_primeira_compra,
        DATE_FORMAT(MIN(data_pagamento), '%Y-%m') AS mes_cohort
    FROM Pagamento
    GROUP BY idCliente
),
Financeiro_Base AS (
    -- 2. Calcular o GMV com base nos itens do pedido
    SELECT 
        ped.id_pedido,
        pag.idCliente,
        DATE(pag.data_pagamento) AS data_pagamento,
        SUM(ip.preco_uni * ip.qtd_item) AS gmv
        -- Os campos de comissão e custo de entrega vão entrar aqui
    FROM Pedido ped
    JOIN Pagamento pag ON ped.id_pedido = pag.idPedido
    JOIN Itens_Pedido ip ON ped.id_pedido = ip.idPedido
    GROUP BY ped.id_pedido, pag.idCliente, DATE(pag.data_pagamento)
)

-- 3. Consulta final cruzando o Cohort com as métricas de recompra e região
SELECT 
    pc.mes_cohort,
    end_c.estado AS regiao,
    
    -- Contagem de clientes do coorte
    COUNT(DISTINCT pc.idCliente) AS total_clientes_cohort,

    -- Taxa de recompra em 30 dias
    COUNT(DISTINCT CASE WHEN DATEDIFF(f.data_pagamento, pc.data_primeira_compra) > 0 AND DATEDIFF(f.data_pagamento, pc.data_primeira_compra) <= 30 THEN f.idCliente END) / COUNT(DISTINCT pc.idCliente) * 100 AS taxa_recompra_d30,
    
    -- Taxa de recompra em 60 dias
    COUNT(DISTINCT CASE WHEN DATEDIFF(f.data_pagamento, pc.data_primeira_compra) > 0 AND DATEDIFF(f.data_pagamento, pc.data_primeira_compra) <= 60 THEN f.idCliente END) / COUNT(DISTINCT pc.idCliente) * 100 AS taxa_recompra_d60,
    
    -- Taxa de recompra em 90 dias
    COUNT(DISTINCT CASE WHEN DATEDIFF(f.data_pagamento, pc.data_primeira_compra) > 0 AND DATEDIFF(f.data_pagamento, pc.data_primeira_compra) <= 90 THEN f.idCliente END) / COUNT(DISTINCT pc.idCliente) * 100 AS taxa_recompra_d90,

    -- Margem Líquida (Atualmente calculando apenas o GMV Bruto)
    SUM(f.gmv) AS margem_liquida_parcial

FROM PrimeiraCompra pc
JOIN Financeiro_Base f ON pc.idCliente = f.idCliente
JOIN RESIDE r ON pc.idCliente = r.id_cliente
JOIN Endereço_Cliente end_c ON r.idEndereço_Cliente = end_c.idEndereço_Cliente
GROUP BY 
    pc.mes_cohort, 
    end_c.estado
ORDER BY 
    pc.mes_cohort, 
    end_c.estado;