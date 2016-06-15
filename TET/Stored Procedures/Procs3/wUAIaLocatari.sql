--***
create PROCEDURE  [dbo].[wUAIaLocatari]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER
AS
begin  
set transaction isolation level READ UNCOMMITTED  
  
 Declare  @abonat varchar(20) 
	
	select   
		@abonat = isnull(@parXML.value('(/row/@codabonat)[1]','varchar(20)'),'')

select top 100  RTRIM(l.Abonat)as abonat,RTRIM(l.Locatar)as locatar,RTRIM(l.Nume)as nume,CONVERT(decimal(12,2),l.Cant_contractata)as cant_contractata,
				RTRIM(l.Banca)as banca,RTRIM(l.Cont_banca)as cont_banca,RTRIM(l.Pers_contact)as pers_contact,RTRIM(l.Strada)as strada,
				RTRIM(l.Adr_nr)as adr_nr,RTRIM(l.Adr_bl)as adr_bl,RTRIM(l.Adr_sc)as adr_sc,RTRIM(l.Adr_ap)as adr_ap,RTRIM(l.Cod_postal)as cod_postal,
				RTRIM(l.Email)as email,RTRIM(Tel_fix)as tel_fix,RTRIM(l.Tel_mobil)as tel_mobil,RTRIM(l.Tel_fax)as tel_fax,RTRIM(l.Nr_autorizatie)as nr_autorizatie,
				CONVERT(decimal(12,2),l.Suprafata)as suprafata, RTRIM(l.Tip)as tip,CONVERT(decimal(12,2),l.Norma_apa)as norma_apa,
				CONVERT(decimal(12,2),l.Canal)AS canal,CONVERT(decimal(12,2),l.Meteo)as meteo,CONVERT(decimal(12,2),l.TaxaD)as taxaD,
				l.Id_contract as id_contract,convert(bit,l.AdrFact) as adresa_facturare,RTRIM(l.Tip_confirmare)as tip_confirmare,RTRIM(l.Tip_locatar)as tip_locatar,
				CONVERT(decimal(12,2),l.Nr_containere) as nr_containere,RTRIM(l.Centru)as centru,RTRIM(Nr_act)as nr_act,RTRIM(l.CNP)as CNP,
				l.Validat,RTRIM(l.Explicatii)as explicatii,RTRIM(l.ObActivitate)as obActivitate,RTRIM(l.ServiciuImplicit)as serviciuImplicit,
				RTRIM(l.TipContainer) as tipContainer,
				rtrim(s.Denumire_Strada)+' ,nr '+RTRIM(l.Adr_nr)+' ,bl '+RTRIM(l.Adr_bl)+' ,sc '+RTRIM(l.Adr_sc)+' ,ap '+RTRIM(l.Adr_ap) as adresa,
				RTRIM(u.Contract)as contract,RTRIM(t.denumire) as denTip_locatar,rtrim(s.Denumire_Strada) as denStrada

from locatari l left outer join Strazi s on l.Strada=s.Strada
				left OUTER JOIN	UAcon u on u.Id_contract=l.Id_contract
				left outer join tipLocatariUA t on l.Tip_locatar=t.Tip
				left outer join Centre cc on l.Centru=cc.Centru
where l.Abonat=@abonat
order by l.Locatar
for xml raw
end
--select * from locatari where abonat='10000392'
--sp_help locatari: locatar,nume,adresa,adresa facturare,cnp,contract,nr_act,explicatii,,cant_contr,
