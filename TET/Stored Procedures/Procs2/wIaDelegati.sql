--***
CREATE procedure wIaDelegati @sesiune varchar(40), @parXML xml
as
declare @Tert varchar(20)
set @Tert = @parXML.value('(/row/@tert)[1]', 'varchar(20)')

declare @rlogic bit,@rnumar float,@ralfa varchar(200)
declare @expeditie bit
set @expeditie=ISNULL((select val_logica from par where Tip_parametru='AR' and Parametru='EXPEDITIE'),0)
if @expeditie is null
	set @expeditie=0
if @expeditie=1
	set @Tert=''

select rtrim(identificator) as idd,rtrim(descriere) as persoana,left(buletin,2) as serie,SUBSTRING(buletin,4,10) as numar,RTRIM(eliberat) as eliberat,
(case when p.Valoare=rtrim(identificator) then 1 else 0 end) as ordine
from infotert 
left outer join proprietati p on p.tip='TERT' and p.cod=@Tert and p.cod_proprietate='UltDelegat'
where tert=@Tert AND Subunitate='C1'
order by ordine desc, persoana
for xml raw
