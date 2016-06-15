/****** Object:  StoredProcedure [dbo].[wUAIaTipurideincasare]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAIaTipurideincasare] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
set transaction isolation level READ UNCOMMITTED
select rtrim(a.id) as id,rtrim(a.denumire) as denumire,
RTRIM(a.cont_specific) as cont,rtrim(a.export) as export,
rtrim(a.loc_de_munca) as lm,rtrim(b.denumire_cont) as dencont,rtrim(c.denumire) as denlm    
from tipuri_de_incasare a
left outer join conturi b on a.Cont_specific=b.cont
left outer join lm c on a.loc_de_munca=c.cod
for xml raw
end
