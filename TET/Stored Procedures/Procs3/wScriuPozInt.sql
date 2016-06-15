--***
create procedure [dbo].[wScriuPozInt] @sesiune varchar(50), @parXML xml
as
declare @eroare varchar(1000)
set @eroare=''
declare @userASiS varchar(10)
begin try
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	declare @masina varchar(50), @data datetime, @data_antet datetime, @update int, @o_masina varchar(50)
	declare @fisa varchar(50), @interventie varchar(20), @explicatii varchar(50), @nr_pozitie int, @data_fisa datetime
	declare @idActivitati int, @idPozActivitati int	

	
	select	@masina=@parXML.value('(row/row/@masina)[1]','varchar(50)'),
			@data=@parXML.value('(row/row/@data)[1]','datetime'),
			@update=isnull(@parXML.value('(row/row/@update)[1]','int'),0),
			@interventie=isnull(@parXML.value('(row/row/@interventie)[1]','varchar(20)'),''),
			@explicatii=isnull(@parXML.value('(row/row/@explicatii)[1]','varchar(50)'),''),
			@idActivitati=isnull(@parXML.value('(row/row/@idActivitati)[1]','int'),''),
			@idPozActivitati=isnull(@parXML.value('(row/row/@idPozActivitati)[1]','int'),''),
			@o_masina=isnull(@parXML.value('(row/row/@o_masina)[1]','varchar(50)'),'')
	if @data is null set @data=@parXML.value('(row/linie/@data)[1]','datetime')
	if @data is null set @data=@parXML.value('(row/@data)[1]','datetime')
	if not exists (select 1 from masini m where m.cod_masina=@masina)
		raiserror('Utilajul nu exista!',16,1)
	if (@update=0 or @masina<>@o_masina)
		and exists (select 1 from activitati a where a.masina=@masina and month(a.Data)=month(@data) and year(a.data)=year(@data) and tip='FI')
			raiserror('Masina este folosita deja in aceasta luna!',16,1)
	set @data_fisa=@data
	if (@update=0)
		begin
			set @fisa = isnull( (select MAX(convert(int,fisa)) from activitati a where ISNUMERIC(fisa)=1) , 0) + 1
			INSERT INTO activitati (Tip,Fisa,Data,Masina,Comanda,Loc_de_munca,Comanda_benef,lm_benef,Tert,Marca,Marca_ajutor,Jurnal)
			select 'FI' tip, @fisa, @data, @masina, '', '', '', '', '', '', '', ''		--> scriu in activitati
			select @idActivitati=ident_current('activitati')
			INSERT INTO pozactivitati(Tip, Fisa, Data, Numar_pozitie, Traseu, Plecare, Data_plecarii, Ora_plecarii, 
					Sosire, Data_sosirii, Ora_sosirii, Explicatii, Comanda_benef, Lm_beneficiar, Tert, Marca, Utilizator, 
					Data_operarii, Ora_operarii, Alfa1, Alfa2, Val1, Val2, Data1, idActivitati
					)
			select 'FI' Tip, @fisa, @data, 1, '', '', @data, '0000',					--> scriu o linie in pozactivitati
					'', @data, '2300', @explicatii, '' Comanda_benef, '' Lm_beneficiar, '' Tert, '' Marca, @userASiS Utilizator,
					convert(varchar(20),getdate(),102) Data_operarii, replace(convert(varchar(20),getdate(),108),':','') Ora_operarii,
					'FI' Alfa1, @interventie, 0 Val1, 0 Val2, '1901-1-1' Data1, @idActivitati
			select @idPozActivitati=ident_current('pozactivitati')
			set @nr_pozitie=1		--> voi scrie si in elemactivitati, dar va merge la fel si in adaugare
			set @parXML=@parXML.query('/row')
		end
	else
	begin
		if not exists (select 1 from activitati a where a.Masina=@masina)
			raiserror ('Nu exista activitate pentru utilajul ales pe luna aceasta! Adaugati inainte de a modifica!',16,1)
		select top 1 @fisa=a.fisa, @nr_pozitie=isnull(e.Numar_pozitie,1), @data_fisa=a.Data --> aleg o fisa si o pozitie pe care sa modific datele
			from activitati a left join elemactivitati e on e.Fisa=a.Fisa and e.Data=a.Data
			where a.masina=@o_masina and month(a.Data)=month(@data) and year(a.Data)=year(@data)
			order by a.data desc
		if (@masina<>@o_masina)		--> inlocuire masina daca s-a schimbat codul
			update a set masina=@masina from activitati a where a.masina=@o_masina and month(a.Data)=month(@data) and year(a.Data)=year(@data)
		set @parXML=@parXML.query('/row/row')
	end
	if not exists (select 1 from elemactivitati ea where ea.fisa=@fisa and ea.Numar_pozitie=@nr_pozitie and ea.data=@data_fisa and
						month(ea.Data)=month(@data) and year(ea.Data)=year(@data) and ea.Element=@interventie)
		insert into elemactivitati(Tip, Fisa, Data, Numar_pozitie, Element, Valoare, Tip_document, Numar_document, Data_document, idPozActivitati
		)
		select 'FI' Tip, @fisa Fisa, @data_fisa Data, @nr_pozitie Numar_pozitie, @interventie Element, 0 Valoare, '' Tip_document, '' Numar_document, 
			'1901-1-1' Data_document, @idPozActivitati
	else
		update ea set valoare=0 from elemactivitati ea 
			where ea.Fisa=@fisa and ea.Numar_pozitie=@nr_pozitie and ea.Element=@interventie and
					month(ea.Data)=month(@data) and year(ea.Data)=year(@data) and ea.data=@data_fisa
	----------------------------------------------
	
	--> se modifica elementul OREBORD din dreptul datei curente; pe viitor ar trebui (probabil) sa se recalculeze
		-->	si pentru eventualele fise care ar fi operate dinainte dar cu data mai mare decat a fisei curente:
	
	declare @oreBordAnterior decimal(15,5), @OSL decimal(15,5)
	select @oreBordAnterior=0
	
	select top 1 @oreBordAnterior=ea.valoare
	from elemactivitati ea
	inner join activitati a on a.Tip=ea.Tip and a.Fisa=ea.Fisa and a.Data=ea.Data and a.Masina=@masina  
	where ea.Element='OREBORD' and ea.data<@data_fisa and a.Tip='FL'
	order by ea.data desc

	if exists (select 1 from elemactivitati ea 
			where ea.Fisa=@fisa and ea.Numar_pozitie=@nr_pozitie and ea.Element='OREBORD' and
					month(ea.Data)=month(@data) and year(ea.Data)=year(@data) and ea.data=@data_fisa)
		update ea set valoare=@oreBordAnterior
		from elemactivitati ea 
			where ea.Fisa=@fisa and ea.Numar_pozitie=@nr_pozitie and ea.Element='OREBORD' and
					month(ea.Data)=month(@data) and year(ea.Data)=year(@data) and ea.data=@data_fisa
	else 
		insert into elemactivitati(Tip, Fisa, Data, Numar_pozitie, Element, Valoare, Tip_document, Numar_document, Data_document)
		select 'FI' Tip, @fisa Fisa, @data_fisa Data, @nr_pozitie Numar_pozitie, 'OREBORD' Element, @oreBordAnterior Valoare, '' Tip_document, '' Numar_document, 
			'1901-1-1' Data_document
	
	
	----------------------------------------------
	exec wIaPozInt @sesiune,@parXML
end try
begin catch
	set @eroare=ERROR_MESSAGE()
	if len(@eroare)>0
	set @eroare='wScriuPozInt:'+
		char(10)+rtrim(@eroare)
end catch

if len(@eroare)>0
	raiserror(@eroare,16,1)
