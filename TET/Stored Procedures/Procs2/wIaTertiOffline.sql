--***
create procedure wIaTertiOffline @sesiune varchar(50),@parXML XML
as
if exists(select * from sysobjects where name='wIaTertiOfflineSP' and type='P')
begin
	declare @returnValue int
	exec @returnValue=wIaTertiOfflineSP @sesiune, @parXML 
	return @returnValue
end

/* procedura EroriSpecificeTerti poate se poate folosi pt a nu permite alegerea tuturor tertilor pt. facturare.
E o procedura specifica, dezvoltata dupa cerintele clientului */
declare @potValidaTerti bit, @rezultat varchar(max), @sub varchar(13)
if exists(select * from sysobjects where name='EroriSpecificeTerti' and type='FN')
	set @potValidaTerti = 1
else 
	set @potValidaTerti = 0

exec luare_date_par @tip='GE', @par='SUBPRO', @val_l=0, @val_n=0, @val_a=@sub output

declare @expeditie bit
set @expeditie=ISNULL((select val_logica from par where Tip_parametru='AR' and Parametru='EXPEDITIE'),0)
if @expeditie is null
	set @expeditie=0

select 
	rtrim(t.Tert) as "@cod", rtrim(t.Denumire) as "@denumire",rtrim(t.Cod_fiscal) as "@cod_fiscal",
	rtrim(t.Localitate) as "@localitate",rtrim(t.Judet) as "@judet",rtrim(t.Adresa) as "@adresa",
	rtrim(t.Telefon_fax) as "@telefon_fax",
	rtrim(t.Banca) as "@banca",rtrim(t.Cont_in_banca) as "@cont_in_banca",
	convert(int,Sold_ca_beneficiar) as "@categorie_pret", rtrim(it.Banca3) as "@NrORC"
	-- trebuie aduse erori specifice?  ,(case when @potValidaTerti=1 THEN dbo.EroriSpecificeTerti('<row tert="'+RTRIM(tert)+'" data="'+convert(varchar,getdate(),101)+'"/>') else '' end) as "@eroare"
	,(
		select 
			idlocatie as "@idlocatie" , locatie as "@locatie", judet as "@judet", localitate as "@localitate", adresa as "@adresa",
			banca as "@banca", cont as "@cont"
		from 
			(select '' as idlocatie,'Sediu central' as locatie,rtrim(Judet) as judet,rtrim(Localitate) as localitate,rtrim(Adresa) as adresa,rtrim(Banca) as banca,rtrim(Cont_in_banca) as cont
			from terti where tert=t.Tert and t.Subunitate=@sub
			union all
			select rtrim(identificator) as idlocatie,rtrim(Descriere) as locatie,rtrim(Telefon_fax2) as judet,rtrim(Pers_contact) as localitate,rtrim(e_mail) as adresa,RTRIM(banca2) as banca,
				RTRIM(Cont_in_banca2) as cont 
			from infotert where subunitate=@sub and identificator<>'' and tert=t.Tert) locatii
		for xml path('locatie'), type
	) as 'locatii',
(
	select rtrim(identificator) as "@idd", rtrim(descriere) as "@persoana", left(buletin,2) as "@serie", rtrim(SUBSTRING(buletin,4,10)) as "@numar", RTRIM(eliberat) as "@eliberat"
	from infotert where tert=t.Tert AND Subunitate='C1'
	for xml path('persoana'), type
) as 'delegati'
from terti t 
left join infotert it on it.Subunitate=@sub and it.Tert=t.Tert and it.Identificator=''
where t.Subunitate=@sub
for xml path('row') 
