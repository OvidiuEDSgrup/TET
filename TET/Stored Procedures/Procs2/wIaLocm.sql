
--***
CREATE PROCEDURE [dbo].[wIaLocm] @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @doc XML, @areDetalii int

SET @doc = (
		SELECT dbo.wfIaLMcopii(@parXML, '')
		)
SET @doc = (
		SELECT @doc
		FOR XML path('Ierarhie')
		)

--IF @doc IS NOT NULL
--	SET @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

IF EXISTS (SELECT 1 FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'lm' AND sc.NAME = 'detalii')
	SET @areDetalii = 1
ELSE
	SET @areDetalii = 0

select @areDetalii areDetaliiXml for xml raw, root('Mesaje')

SELECT @doc
FOR XML path('Date')
	/*
#start populare
LM
C, CG, L
Locuri de munca
Locuri de munca
('','',1,'Loc de munca','','@lm','',0,'','','','varchar',9,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',2,'Denumire','','@denlm','',0,'','','','varchar',30,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',3,'Centru','','@centru','',0,'','','','varchar',8,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',4,'Denumire centru','','@dencentru','',0,'','','','varchar',20,'C','C','','','','',1,'','','',1,0,0,'',0,1)

('','',1,'Loc de munca','','@lm','',0,'','','','char',9,'C','C','','','','',1,'','','',1,1,1,'',0,1),
('','',2,'Denumire','','@denlm','',0,'','','','char',30,'C','C','','','','',1,'','','',1,1,1,'',0,1),
('','',3,'Nivel','','@nivel','',0,'','','','smallint','','C','N','','','','',0,'','','',1,0,0,'',0,1),
('','',4,'Loc de munca parinte','','@parinte','@denparinte','','','','','char',9,'C','AC','wLocm','','','',1,'','','',1,1,1,'',0,1),
('','',5,'Denumire loc de munca parinte','','@denparinte','','','','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',6,'Tip comanda','','@tipcomanda','@dentipcomanda','','','','','char',1,'C','CB','','P,R,X,T,S,L,G,D','Productie terti,Servicii terti,Auxiliara,Transport,Semifabricat,Regie sectie,Regie generala,Desfacere','',0,'','','',1,1,1,'',0,1),
('','',7,'Denumire tip comanda','','@dentipcomanda','','','','','','char',20,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',8,'Comanda','','@comanda','@dencomanda','','','','','char',20,'C','AC','wComenzi','','','',0,'','','',1,1,1,'',0,1),
('','',9,'Denumire comanda','','@dencomanda','','','','','','char',80,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',10,'Centru','','@centru','@dencentru',0,'','','','char',6,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',11,'Denumire centru','','@dencentru','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1)
#sfarsit populare
*/
