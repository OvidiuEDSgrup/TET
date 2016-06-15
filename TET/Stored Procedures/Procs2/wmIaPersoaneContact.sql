--***
CREATE procedure wmIaPersoaneContact @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmIaPersoaneContactSP' and type='P')
begin
	exec wmIaPersoaneContactSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare @eroare varchar(1000), @utilizator varchar(50), @tert varchar(100), @idPunctLivrare varchar(100), @subunitate varchar(50),
	@xml1 xml, @xml2 xml, @xml3 xml, @xml4 xml, @xml5 xml, @xml6 xml, @xml7 xml, @telefon varchar(50), @NrRegCom varchar(50), @email varchar(500)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
	if @utilizator is null 
		return -1
	
	select	@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
		@idPunctLivrare=@parXML.value('(/row/@pctliv)[1]','varchar(100)')

	select	@subunitate=rtrim(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru ='SUBPRO'
	
	select	@telefon = rtrim(t.Telefon_fax),
			@email = rtrim(it.e_mail)
	from terti t
	left join infotert it on  it.Subunitate=@subunitate and it.Tert=t.Tert and it.Identificator=''
	where t.subunitate=@subunitate and t.Tert = @tert 
	
	-- persoanele de contact
	set @xml1 = 
	(select 
		rtrim(Identificator) as cod, RTRIM(it.Descriere) as denumire,
		RTRIM(it.Telefon_fax2) as info,
		'tel:'+RTRIM(it.Telefon_fax2) as actiune, rtrim(it.Descriere) as nume, rtrim(it.Telefon_fax2) as telefon, rtrim(it.e_mail) as email,
			 rtrim(it.observatii) as yahoomess, rtrim(it.Identificator) as id
	from infotert it
	where it.Subunitate='C1' and it.Tert=@tert
	for xml raw)
	
	set @xml2 = ( select '<NOU>' cod, '<Contact nou>' denumire for xml raw)
	
	if len(@telefon)>0
		set @xml3 = 
			(select 'tel:'+@telefon as actiune, 'Telefon sediu' denumire, @telefon as info
			for xml raw)
	
	if len(@email)>0
		set @xml4 = 
			(select 'mailto:'+@email as actiune, 'Email sediu' denumire, @email as info
			for xml raw)
	
	select @xml1, @xml2, @xml3, @xml4 
	for xml raw('Date')

   	select 'wmScriuPersoaneContact' as detalii, 0 as areSearch,'D' as tipdetalii, 'Persoane de contact:' as titlu,
		dbo.f_wmIaForm('CN') form
	for xml raw,Root('Mesaje')
end try

begin catch
	set @eroare=error_message() + ' (wmIaPersoaneContact)'
end catch


if (1 = @@NESTLEVEL)
	select '@tert' as atribute for xml raw('atributeRelevante'),root('Mesaje')

if @eroare is not null
	raiserror(@eroare,11,1)
