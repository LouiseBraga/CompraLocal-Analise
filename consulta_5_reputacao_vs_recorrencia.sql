-- Consulta 5 - Reputação vs Recorrência: Correlação por loja

WITH Avaliacoes AS (
    -- 1. Calcula a nota média de cada loja
    SELECT 
        p.idlojista AS id_loja,
        AVG(a.nota) AS nota_media
    FROM Avaliacao a
    JOIN Produto p ON a.idProduto = p.id_produto
    GROUP BY p.idlojista
),
Vendas_Clientes AS (
    -- 2. Mapeia quantos pedidos cada cliente fez em cada loja (usando o caminho do Carrinho)
    SELECT 
        p.idlojista AS id_loja,
        pag.idCliente,
        COUNT(DISTINCT ped.id_pedido) AS qtd_pedidos_cliente
    FROM Produto p
    JOIN Itens_Carrinho ic ON p.id_produto = ic.idProduto
    JOIN Carrinho car ON ic.idCarrinho = car.id_carrinho
    JOIN Pedido ped ON car.id_carrinho = ped.idCarrinho
    JOIN Pagamento pag ON ped.id_pedido = pag.idPedido
    GROUP BY p.idlojista, pag.idCliente
),
Metricas_Vendas AS (
    -- 3. Consolida o volume total e a quantidade de clientes recorrentes por loja
    SELECT 
        id_loja,
        SUM(qtd_pedidos_cliente) AS volume_vendas_total,
        COUNT(DISTINCT idCliente) AS total_clientes_unicos,
        -- Conta apenas clientes que compraram mais de 1 vez na mesma loja
        COUNT(DISTINCT CASE WHEN qtd_pedidos_cliente > 1 THEN idCliente END) AS clientes_recorrentes
    FROM Vendas_Clientes
    GROUP BY id_loja
),
Reembolsos_Loja AS (
    -- 4. Conta os reembolsos atrelados aos produtos de cada loja
    SELECT 
        p.idlojista AS id_loja,
        COUNT(DISTINCT r.id_reembolso) AS qtd_reembolsos
    FROM Reembolso r
    JOIN Nota_Fiscal nf ON r.idNota_Fiscal = nf.id_nota_fiscal
    JOIN Pagamento pag ON nf.id_nota_fiscal = pag.idNota_Fiscal
    JOIN Pedido ped ON pag.idPedido = ped.id_pedido
    JOIN Carrinho car ON ped.idCarrinho = car.id_carrinho
    JOIN Itens_Carrinho ic ON car.id_carrinho = ic.idCarrinho
    JOIN Produto p ON ic.idProduto = p.id_produto
    GROUP BY p.idlojista
)

-- 5. Consulta Final: Cruzamento de métricas e identificação dos outliers
SELECT 
    l.nome_loja,
    ROUND(COALESCE(av.nota_media, 0), 2) AS nota_media,
    COALESCE(mv.volume_vendas_total, 0) AS volume_vendas,
    
    -- Cálculos de Taxa (Tratando divisões por zero com NULLIF)
    ROUND(COALESCE((mv.clientes_recorrentes / NULLIF(mv.total_clientes_unicos, 0)) * 100, 0), 2) AS taxa_recompra_percentual,
    ROUND(COALESCE((rl.qtd_reembolsos / NULLIF(mv.volume_vendas_total, 0)) * 100, 0), 2) AS taxa_reembolso_percentual,

    -- Classificação dos outliers
    CASE 
        WHEN av.nota_media >= 4.5 AND (mv.clientes_recorrentes / NULLIF(mv.total_clientes_unicos, 0)) < 0.10 THEN 'Alerta: Nota Alta, Recompra Baixa'
        WHEN av.nota_media <= 3.0 AND (mv.clientes_recorrentes / NULLIF(mv.total_clientes_unicos, 0)) > 0.30 THEN 'Oportunidade: Nota Baixa, Recompra Alta (Nicho/Preço)'
        ELSE 'Comportamento Padrão'
    END AS status_outlier

FROM Lojista l
LEFT JOIN Avaliacoes av ON l.id_loja = av.id_loja
LEFT JOIN Metricas_Vendas mv ON l.id_loja = mv.id_loja
LEFT JOIN Reembolsos_Loja rl ON l.id_loja = rl.id_loja
ORDER BY status_outlier ASC, nota_media DESC;