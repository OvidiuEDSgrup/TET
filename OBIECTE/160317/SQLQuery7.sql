-- Prepare some bigger XML data
 
DECLARE @xml XML 
DECLARE @detail VARCHAR(4000) = '<orderdata><orderId id="123">1</orderId><quantity UM="altceva">3</quantity><createdBy user="operatorul">SYSTEM</createdBy><created data="02/16/2016">2015-07-31</created></orderdata><orderdata><orderId>2</orderId><quantity>2</quantity><createdBy>SYSTEM</createdBy><created>2015-07-31</created></orderdata><orderdata><orderId>4</orderId><quantity>3</quantity><createdBy>SYSTEM</createdBy><created>2015-07-31</created></orderdata><orderdata><orderId>10</orderId><quantity>3</quantity><createdBy>SYSTEM</createdBy><created>2015-07-31</created></orderdata><orderdata><orderId>21</orderId><quantity>3</quantity><createdBy>SYSTEM</createdBy><created>2015-07-31</created></orderdata><orderdata><orderId>31</orderId><quantity>3</quantity><createdBy>SYSTEM</createdBy><created>2015-07-31</created></orderdata><orderdata><orderId>33</orderId><quantity>3</quantity><createdBy>SYSTEM</createdBy><created>2015-07-31</created></orderdata>'
DECLARE @details VARCHAR(MAX) = ''
 
SELECT @details = @detail + @details
FROM master..spt_values
WHERE spt_values.type='P'
 
SET @xml = '<request><list>' + @details + '</list></request>'
 
DECLARE @dump INT;
 
-- OpenXml
 
PRINT '======='
PRINT 'OPENXML'
PRINT '======='
 
SET STATISTICS IO ON ;
SET STATISTICS TIME ON;
 
DECLARE @hnd INT
EXEC sp_xml_preparedocument @hnd OUTPUT, @xml
SELECT orderId, quantity, 
createdBy, created 
FROM OPENXML(@hnd, '/request/list/orderdata', 2) 
 WITH (orderId INT 'orderId', 
 quantity FLOAT 'quantity', 
 createdBy VARCHAR(20) 'createdBy', 
 created datetime 'created')
EXEC sp_xml_removedocument @hnd
 
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
 
-- XQuery with /text()
 
PRINT ''
PRINT '==================='
PRINT 'XQuery With /text()'
PRINT '==================='
 
SET STATISTICS IO ON ;
SET STATISTICS TIME ON;
 
SELECT
t.c.value('(orderId/text())[1]', 'INT') as orderId, 
t.c.value('(quantity/text())[1]', 'INT') as quantity,
t.c.value('(createdBy/text())[1]', 'VARCHAR(20)') as createdBy, 
t.c.value('(created/text())[1]', 'datetime') as created 
FROM @xml.nodes('/request/list/orderdata') t(c)
 
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
 
-- XQuery without /text()
 
PRINT ''
PRINT '======'
PRINT 'XQuery'
PRINT '======'
 
SET STATISTICS IO ON ;
SET STATISTICS TIME ON;
 
SELECT
t.c.value('orderId[1]', 'INT') as orderId, 
t.c.value('quantity[1]', 'INT') as quantity,
t.c.value('createdBy[1]', 'VARCHAR(20)') as createdBy, 
t.c.value('created[1]', 'datetime') as created 
FROM @xml.nodes('/request/list/orderdata') t(c)
 
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- XQuery with /text()
 
PRINT ''
PRINT '==================='
PRINT 'XQuery With /@attribute'
PRINT '==================='
 
SET STATISTICS IO ON ;
SET STATISTICS TIME ON;
 
SELECT
t.c.value('(orderId/@id)[1]', 'INT') as orderId, 
t.c.value('(quantity/@UM)[1]', 'varchar(10)') as quantity,
t.c.value('(createdBy/@user)[1]', 'VARCHAR(20)') as createdBy, 
t.c.value('(created/@data)[1]', 'datetime') as created 
FROM @xml.nodes('/request/list/orderdata') t(c)
 
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;