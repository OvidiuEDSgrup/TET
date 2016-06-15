--***
create procedure wIaCarduriFidelizare(@sesiune varchar(50), @parXML xml)
as

--> extragere parametri/filtre din xml si pregatire date:
declare @subunitate varchar(20), @valoarePunct float
exec luare_date_par @tip='PV', @par='VALPUNCTI', @val_l=0, @val_n=@valoarePunct output, @val_a=''

select @subunitate=isnull((select top 1 val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'),'1')

declare @tert varchar(100), @numePosesor varchar(100), @numeTert varchar(100), @f_card varchar(20)
select @tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
		@numeTert='%'+@parXML.value('(/row/@numetert)[1]','varchar(20)')+'%',
		@numePosesor='%'+@parXML.value('(/row/@numeposesor)[1]','varchar(100)')+'%',
		@f_card='%'+@parXML.value('(/row/@f_card)[1]','varchar(100)')+'%'

--> select propriu-zis:
select top 100 uid, rtrim(c.Tert) as tert, rtrim(Punct_livrare) as punctlivrare, rtrim(Id_Persoana_contact) as persoanacontact, rtrim(Mijloc_de_transport) as mijloctransport, 
		rtrim(Nume_posesor_card) as numeposesor, rtrim(Telefon_posesor_card) as telposesor, rtrim(Email_posesor_card) as emailposesor, --Detalii_xml,
			rtrim(t.Denumire) as numetert, '('+rtrim(Punct_livrare)+') '+rtrim(pl.Descriere) as numepunctlivrare, 
			'('+rtrim(Id_Persoana_contact)+') '+rtrim(pc.Descriere) as numepersoanacontact,
		isnull(convert(varchar(30), convert(decimal(12,2),p.puncte)),0) puncte,
		isnull(convert(varchar(30), convert(decimal(12,2),p.puncte))+'('+CONVERT(varchar(30),CONVERT(decimal(12,2), convert(float,p.puncte) * @valoarePunct))+' RON)',0) denpuncte,
		c.blocat as blocat,
		(case when c.blocat = 1 then 'DA' else 'NU' end) as denblocat,
		c.detalii as detalii
from CarduriFidelizare c 
left join terti t on c.Tert=t.Tert and t.subunitate=@subunitate
left join infotert pl on pl.Tert=c.Tert and pl.Identificator=c.Punct_livrare and pl.Subunitate=@subunitate
left join infotert pc on pc.Tert=c.Tert and rtrim(pc.Identificator)=rtrim(c.Id_Persoana_contact) and rtrim(pc.Subunitate)='C'+@subunitate
left join (select UID_card, sum((case when p.tip='D' then 1 else -1 end) * p.puncte) as puncte 
			from PvPuncte p 
			group by p.UID_card) p on p.UID_card=c.UID
where (@tert is null or c.Tert=@tert)
	and (@numePosesor is null or Nume_posesor_card like @numePosesor)
	and (@numeTert is null or t.Denumire like @numeTert)
	and (@f_card is null or c.UID like @f_card)
for xml raw

select 1 as areDetaliiXml for xml raw, root('Mesaje')
