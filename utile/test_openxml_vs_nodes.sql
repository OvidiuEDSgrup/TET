-- Prepare some bigger XML data
 
DECLARE @xml XML 
DECLARE @detail VARCHAR(4000) = '<orderdata id="1" UM="3" user="SYSTEM" data="07/31/2015"><orderId id="1">1</orderId><quantity UM="3">3</quantity><createdBy user="SYSTEM">SYSTEM</createdBy><created data="07/31/2015">2015-07-31</created></orderdata><orderdata id="1" UM="3" user="SYSTEM" data="07/31/2015"><orderId id="2">2</orderId><quantity UM="2">2</quantity><createdBy user="SYSTEM">SYSTEM</createdBy><created data="07/31/2015">2015-07-31</created></orderdata><orderdata id="1" UM="3" user="SYSTEM" data="07/31/2015"><orderId id="4">4</orderId><quantity UM="3">3</quantity><createdBy user="SYSTEM">SYSTEM</createdBy><created data="07/31/2015">2015-07-31</created></orderdata><orderdata id="1" UM="3" user="SYSTEM" data="07/31/2015"><orderId id="10">10</orderId><quantity UM="3">3</quantity><createdBy user="SYSTEM">SYSTEM</createdBy><created data="07/31/2015">2015-07-31</created></orderdata><orderdata id="1" UM="3" user="SYSTEM" data="07/31/2015"><orderId id="21">21</orderId><quantity UM="3">3</quantity><createdBy user="SYSTEM">SYSTEM</createdBy><created data="07/31/2015">2015-07-31</created></orderdata><orderdata id="1" UM="3" user="SYSTEM" data="07/31/2015"><orderId id="31">31</orderId><quantity UM="3">3</quantity><createdBy user="SYSTEM">SYSTEM</createdBy><created data="07/31/2015">2015-07-31</created></orderdata><orderdata id="1" UM="3" user="SYSTEM" data="07/31/2015"><orderId id="33">33</orderId><quantity UM="3">3</quantity><createdBy user="SYSTEM">SYSTEM</createdBy><created data="07/31/2015">2015-07-31</created></orderdata>'
DECLARE @details VARCHAR(MAX) = ''
 
SELECT @details = @detail + @details
FROM master..spt_values
WHERE spt_values.type='P'
 
SET @xml = '<request id="1" UM="3" user="SYSTEM" data="07/31/2015"><list id="1" UM="3" user="SYSTEM" data="07/31/2015">' + @details + '</list></request>'
 
--goto final
 
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

-- XQuery with /element/@attribute
 
PRINT ''
PRINT '==================='
PRINT 'XQuery With /element/@attribute'
PRINT '==================='
 
SET STATISTICS IO ON ;
SET STATISTICS TIME ON;
 
SELECT
t.c.value('(orderId/@id)[1]', 'INT') as orderId, 
t.c.value('(quantity/@UM)[1]', 'int') as quantity,
t.c.value('(createdBy/@user)[1]', 'VARCHAR(20)') as createdBy, 
t.c.value('(created/@data)[1]', 'datetime') as created 
FROM @xml.nodes('/request/list/orderdata') t(c)
 
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- XQuery with /@attribute
 
PRINT ''
PRINT '==================='
PRINT 'XQuery With /@attribute'
PRINT '==================='
 
SET STATISTICS IO ON ;
SET STATISTICS TIME ON;
 
SELECT
t.c.value('(@id)[1]', 'INT') as orderId, 
t.c.value('(@UM)[1]', 'int') as quantity,
t.c.value('(@user)[1]', 'VARCHAR(20)') as createdBy, 
t.c.value('(@data)[1]', 'datetime') as created 
FROM @xml.nodes('/request/list/orderdata') t(c)
 
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- XQuery with ../@attribute
 
PRINT ''
PRINT '==================='
PRINT 'XQuery With ../@attribute'
PRINT '==================='
 
SET STATISTICS IO ON ;
SET STATISTICS TIME ON;
 
SELECT
t.c.value('(@id)[1]', 'INT') as orderId, 
t.c.value('(@UM)[1]', 'int') as quantity,
t.c.value('(@user)[1]', 'VARCHAR(20)') as createdBy, 
t.c.value('(@data)[1]', 'datetime') as created 
FROM @xml.nodes('/request/list') t(c)
 
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

final:

-- XQuery with cross apply
 
PRINT ''
PRINT '==================='
PRINT 'XQuery With cross apply'
PRINT '==================='
 
SET STATISTICS IO ON ;
SET STATISTICS TIME ON;
--select @xml
SELECT --t.c.query('.'),
t.c.value('(@id)[1]', 'INT') as orderId, 
t.c.value('(@UM)[1]', 'int') as quantity,
t.c.value('(@user)[1]', 'VARCHAR(20)') as createdBy, 
t.c.value('(@data)[1]', 'datetime') as created
--,t.c.query('.')
,
l.c.value('(@id)[1]', 'INT') as orderId, 
l.c.value('(@UM)[1]', 'int') as quantity,
l.c.value('(@user)[1]', 'VARCHAR(20)') as createdBy, 
l.c.value('(@data)[1]', 'datetime') as created
,
o.c.value('(@id)[1]', 'INT') as orderId, 
o.c.value('(@UM)[1]', 'int') as quantity,
o.c.value('(@user)[1]', 'VARCHAR(20)') as createdBy, 
o.c.value('(@data)[1]', 'datetime') as created 
FROM @xml.nodes('/request') t(c)
outer apply t.c.nodes('./list') l(c)
outer apply l.c.nodes('./orderdata') o(c)
 
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;