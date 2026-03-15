O cliente tem a opção de criar pedidos com múltiplos produtos, esses produtos podem ser de diferentes lojas.
Para um pedido bem sucedido(Aquele que passa por todos os processos e chega até o cliente) deve-se guardar as seguintes informações:
#### Obrigatórias
- Produtos relacionados ao pedido e seus **PREÇOS NO MOMENTO DA COMPRA**;
- Destino do pedido, separando endereço, cidade e estado;
- Data de criação do pedido;
- Datas de inicio de preparação de cada loja;
- Data de inicio da entrega de cada loja;
- Data de fim da entrega de cada loja;
- Em caso de algum cupom ser utilizado, as informações do cupom;

Para pedidos mal sucedidos, ou seja, cancelados antes do recebimento do cliente, devem ser guardadas apenas as datas relacionadas as fases pelas quais aquele pedido chegou a passar.
Exemplo: Um pedido que foi cancelado antes de entrar na fase de entrega não pode conter data de inicio da entrega ou data de fim da entrega.

## Relações
- [[RF06-Cupons-Promocionais]]
- [[RF07-Cashback]]

## Tags
#Cadastro 
#Pedidos