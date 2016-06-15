--***
create procedure wOPInchidereConturi(@sesiune varchar(50), @parXML xml) 
as     
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPInchidereConturiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPInchidereConturiSP @sesiune, @parXML output
	return @returnValue
end

if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPInchidereConturi'

declare @data datetime, @lm varchar(13),@com varchar(20),@indbug varchar(20),@stergTVA int,@inchidTVA int,@inchid4423 int,@sterg121 int,@inchid121 int,
	 @inv711_121 int,@subunitate char(9),@lunaBlocata int,@anBlocat int,@mesaj varchar(200),
	 @initializareAnSolduri bit, @inchidTLI bit, @corectiiDate bit, @rulajeLM bit, @Inlocm varchar(20)
/*
declare @p2 xml
set @p2=convert(xml,N'<parametri tipMacheta="O" codMeniu="IC" data="2013-08-31" lm="ADMN" stergTVA="1" inchidTVA="1" sterg121="1" inchid121="1" corectiiDate="0" inchidTLI="1"/>')
exec wOPInchidereConturi @sesiune='AB3AFE74AE2F0',@parXML=@p2
*/
begin try
	select 
		@data=isnull(@parXML.value('(/parametri/@data)[1]','datetime'), '2999-01-01'),
		@lm=isnull(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'),''),
		@com=isnull(@parXML.value('(/parametri/@com)[1]', 'varchar(20)'),''),
		@indbug=replace(isnull(@parXML.value('(/parametri/@indbug)[1]', 'varchar(20)'),''),'.',''),
		@stergTVA=isnull(@parXML.value('(/parametri/@stergTVA)[1]', 'int'),0),
		@inchidTLI=isnull(@parXML.value('(/parametri/@inchidTLI)[1]', 'int'),1),
		@corectiiDate=isnull(@parXML.value('(/parametri/@corectiiDate)[1]', 'int'),1),
		@inchidTVA=isnull(@parXML.value('(/parametri/@inchidTVA)[1]', 'int'),0),
		@inchid4423=isnull(@parXML.value('(/parametri/@inchid4423)[1]', 'int'),0),
		@sterg121=isnull(@parXML.value('(/parametri/@sterg121)[1]', 'int'),0),
		@inchid121=isnull(@parXML.value('(/parametri/@inchid121)[1]', 'int'),0),
		@inv711_121=isnull(@parXML.value('(/parametri/@inv711_121)[1]', 'int'),0),
		@initializareAnSolduri=@parXML.value('(/parametri/@initializareAnSolduri)[1]', 'int'),
		@Inlocm = ''
	
	--> se initializeaza soldurile contabile doar daca suntem in decembrie; se init pe anul urmator:
	set @initializareAnSolduri= (case when month(@data)=12 then isnull(@initializareAnSolduri,1) else 0 end)
	
	declare @dataImplementarii datetime
	select @dataImplementarii=dbo.eom(convert(datetime,
			 convert(varchar(20),max(case when parametru='ANULIMPL' then val_numerica else 0 end))
		+'-'+convert(varchar(20),max(case when parametru='LUNAIMPL' then val_numerica else 0 end))
		+'-1'))
	from par where tip_parametru='GE' and parametru in ('ANULIMPL','LUNAIMPL')
	
	select @dataImplementarii=dateadd(d,1,@dataImplementarii)
	if (@data<=@dataImplementarii) raiserror('Nu este permisa nici o operatie inainte de data implementarii!',16,1)
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output       
	exec luare_date_par 'GE', 'LUNABLOC ', 0, @lunaBlocata output ,'' 
	exec luare_date_par 'GE', 'ANULBLOC  ', 0, @anBlocat output ,'' 
	exec luare_date_par 'GE','RULAJELM', @rulajeLM OUTPUT, 0, '' 
			
	-- aici de tratat luna blocata, ca sa nu dea mesaj mai tarziu
	if year(@data)<@anBlocat or (YEAR(@data)=@anBlocat and MONTH(@data)<=@lunaBlocata )
	begin
		raiserror ('Luna selectata este blocata pentru operare!',11,1)
		return -1
	end	 
	
	if year(@data)<year(getdate())-1
		raiserror ('Nu este permisa operatia de inchidere cu mai mult de un an in urma!',16,1)
	if @inchidTVA=1
		set @stergTVA=1
	if @inchid121=1
		set @sterg121=1
		
	/*Setam data pentru datalunii cu EOM */
	SELECT @data=dbo.EOM(@data)

	/** Se apeleaza procedura care realizeaza diferite corectii care tin de inchidere-> daca exista **/
	if @corectiiDate=1 and exists (select 1 from sysobjects where [type]='P' and [name]='corectiiInchidere')
		exec corectiiInchidere @sesiune=@sesiune,@parXML=@parXML

	/* Se apeleaza inchiderea de provizioane, daca exista procedura-> ea va trata si daca se lucreaza cu provizioane sau nu*/
	if exists (select 1 from sysobjects where [type]='P' and [name]='inchidereProvizioane')
	begin
		exec inchidereProvizioane @sesiune=@sesiune,@parXML=@parXML, @data_lunii=@data
		exec fainregistraricontabile @dinTabela=1,@dataSus=@data   
	end
	/* Se apeleaza inchiderea de gestiuni valorice, daca exista procedura*/
	if exists (select 1 from sysobjects where [type]='P' and [name]='inchidereGestiuniValorice')
	begin
		exec inchidereGestiuniValorice @sesiune=@sesiune,@parXML=@parXML
	end
	if @inchidTLI=1
	begin
		declare @dataJos datetime
		set @dataJos=dbo.BOM(@data)
		exec inchidTLI @dataJos=@dataJos, @dataSus=@data, @lm=@lm, @com=@com, @indbug=@indbug
	end

	/* Daca nu se lucreaza cu rulaje pe locuri de munca si s-a trimis un loc de munca completat el are semnificatia de LM al documentelor ce se genereaza
	   NU are semnificatia de filtru 
	 */
	IF @rulajeLM = 0 and @lm <> ''
		select @Inlocm=@lm, @lm=''

	if @StergTVA=1 or @InchidTVA=1 or @Sterg121=1 or @Inchid121=1
	exec inchidere121lm @Data=@data,@Locm=@lm, @Inlocm=@Inlocm,
		@StergTVA=@stergTVA, @InchidTVA=@inchidTVA, @Inchid4423=@inchid4423,
		@Sterg121=@sterg121, @Inchid121=@inchid121, @Inv711_121=@inv711_121

	if @initializareAnSolduri=1
	begin
		declare @anInitializare int
		select @anInitializare=year(@data)+1
		exec initializareAnConturi @sesiune=@sesiune, @an=@anInitializare
	end
				
	declare @nrDocTVA varchar(20),@nrDoc121 varchar(20)
	set @nrDocTVA='IT'+(case when month(@data)<10 then '0' else '' end)+convert(varchar(2),month(@data),102)+convert(varchar(4),year(@data))
	set @nrDoc121='IC'+(case when month(@data)<10 then '0' else '' end)+convert(varchar(2),month(@data),102)+convert(varchar(4),year(@data))
	
	if exists (select 1 from pozncon p where p.subunitate=@subunitate and p.data=@data and p.Tip='IC' and p.Numar=@nrDoc121)
		and exists (select 1 from pozncon p where p.subunitate=@subunitate and p.data=@data and p.Tip='IC' and p.Numar=@nrDocTVA) 
		and @inchid121=1 and @inchidTVA=1
		select 'S-au generat notele contabile '+@nrDoc121+', '+@nrDocTVA+ ' !' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	else
		if exists (select 1 from pozncon p where p.subunitate=@subunitate and p.data=@data and p.Tip='IC' and p.Numar=@nrDoc121)
			and @inchid121=1
			select 'S-a generat nota contabila '+@nrDoc121+ '!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
		else
			if exists (select 1 from pozncon p where p.subunitate=@subunitate and p.data=@data and p.Tip='IC' and p.Numar=@nrDocTVA) 
				and @inchidTVA=1	
				select 'S-a generat nota contabila '+@nrDocTVA+ '!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
			else 	
				if @inchidTLI=1 and exists (select 1 from pozplin where subunitate=@subunitate and data between @datajos and @data and Plata_incasare in ('PC','IC') and cont like '4428%' and numar like 'IT%')
					select 'S-au generat documente PC/IC pentru TVA la incasare!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
				else
				if @corectiiDate=1 
					select 'S-au verificat si eventual corectat unele date (receptii cu prestari, conturi de TVA, etc.)!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
				else
				if (@stergTVA=1 and @inchidTVA=0) or (@sterg121=1 and @inchid121=0)
					select 'Notele contabile au fost sterse!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')	
				else
					select 'Verificati datele, nu a fost efectuata nici o operatie!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' (wOPInchidereConturi)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
