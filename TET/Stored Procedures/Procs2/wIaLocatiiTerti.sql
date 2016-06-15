--***
CREATE procedure wIaLocatiiTerti @sesiune varchar(40), @parXML xml
as
declare @Tert varchar(200), @sub varchar(20)
declare @locatii table(idLocatie varchar(200), locatie varchar(200), judet varchar(200), localitate varchar(200), adresa varchar(200), banca varchar(200), cont varchar(200))

select	@sub=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @sub end)
from par 
where Tip_parametru='GE' and Parametru='SUBPRO'


set @Tert = @parXML.value('(/row/@tert)[1]', 'varchar(200)')

insert into @locatii(idLocatie, locatie, judet, localitate, adresa, banca, cont)
select '' as idLocatie,'Sediu central' as locatie,rtrim(Judet) as judet,rtrim(Localitate) as localitate,rtrim(Adresa) as adresa,rtrim(Banca) as banca,rtrim(Cont_in_banca) as cont
from terti where tert=@Tert
insert into @locatii(idLocatie, locatie, judet, localitate, adresa, banca, cont)
select rtrim(identificator),rtrim(Descriere),rtrim(Telefon_fax2),rtrim(Pers_contact),rtrim(e_mail),RTRIM(banca2),RTRIM(Cont_in_banca2)
from infotert where subunitate=@sub and identificator<>'' and tert=@Tert

select l.*, (case when p.Valoare=rtrim(idLocatie) then 1 else 0 end) as ordine
from @locatii l
left outer join proprietati p on p.tip='TERT' and p.cod=@Tert and p.cod_proprietate='UltLocatie'
order by ordine desc, idLocatie
for xml raw
