/* operatie pt. vizualizare fluturasi cu formular SQL */
create procedure wOPGenFluturasi (@sesiune varchar(50), @parXML xml) 
as     

declare @utilizator varchar(10), @tip varchar(1), @formular varchar(13), 
@luna int, @lunaalfa varchar(15), @an int, @dataJos datetime, @dataSus datetime, 
@tipoperatie int, @lm varchar(9), @marca varchar(6), @sirmarci varchar(1000), @functie varchar(6), 
@card varchar(25), @grupamunca char(1), @grpmexcep int, @tipstat varchar(30), 
@ordonare char(1), @restplpoz int, @textemail varchar(1000),
@profile_name varchar(50), @calefisier varchar(200), @numefisier varchar(200), @file_attachments varchar(1000), 
@inXML varchar(1), @mesaj varchar(254), @debug bit, @CLFrom varchar(100), @caleRaport varchar(1000)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenFluturasi' 

select	@formular = isnull(@parXML.value('(/parametri/@formular)[1]','varchar(13)'),''),	
		@luna = isnull(@parXML.value('(/parametri/@luna)[1]','int'),0),
		@an = isnull(@parXML.value('(/parametri/@an)[1]','int'),0),
		@tipoperatie = isnull(@parXML.value('(/parametri/@tipop)[1]','int'),0),
		@lm = isnull(@parXML.value('(/parametri/@lm)[1]','varchar(9)'),''),
		@marca = isnull(@parXML.value('(/parametri/@marca)[1]','varchar(6)'),''),
		@sirmarci = isnull(@parXML.value('(/parametri/@sirmarci)[1]','varchar(1000)'),''),
		@functie = isnull(@parXML.value('(/parametri/@functie)[1]','varchar(6)'),''),
		@card = isnull(@parXML.value('(/parametri/@card)[1]','varchar(25)'),''),
		@grupamunca = isnull(@parXML.value('(/parametri/@grupamunca)[1]','varchar(1)'),''),
		@grpmexcep = isnull(@parXML.value('(/parametri/@grpmexcep)[1]','int'),''),
		@tipstat = isnull(@parXML.value('(/parametri/@tipstat)[1]','varchar(30)'),''),
		@ordonare = isnull(@parXML.value('(/parametri/@ordonare)[1]','varchar(1)'),''),
		@restplpoz = isnull(@parXML.value('(/parametri/@restplpoz)[1]','int'),''),
		@textemail = isnull(@parXML.value('(/parametri/@textemail)[1]','varchar(1000)'),''),
		@inXML = @parXML.value('(/parametri/@inXML)[1]','varchar(1)'),
		@debug = isnull(@parXML.value('(/parametri/@debug)[1]','bit'),0)
		
	set @dataJos=convert(datetime,str(@luna,2)+'/01/'+str(@an,4))
	set @dataSus=dbo.eom(@dataJos)
	select @lunaalfa=LunaAlfa from fCalendar(@dataSus,@dataSus)
	set @profile_name=dbo.iauParA('PS','PROFILEN')
	set @calefisier=(select top 1 rtrim(val_alfanumerica) from par where Tip_parametru='AR' and Parametru='CALEFORM')

	if @profile_name='' and @tipoperatie=1
		raiserror ('Nu este configurat profile name in tabela par! Configurati parametrul "PS", "PROFILEN". Configurati in SQL Server serviciul de trimis mail-uri!',16,1)
	
	if @formular=''
		select @tip='6', @formular='FLUTURAS'
	if isnull(@tip,'')='' set @tip='6'
	select @CLFrom=CLFrom, @caleRaport=rtrim(CLWhere) from antform where numar_formular=@formular
	
	declare @paramXmlString varchar(max)
----------------------------- formular pentru generare raport -----------------------------
	if @tipoperatie=0
	Begin
		delete from avnefac where terminal=@utilizator
		insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,Contractul, 
		Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22, 
		Cont_beneficiar,Discount) 
		values (@utilizator,'1','FS',@marca,@functie,@dataSus,@card,'',@utilizator,@dataJos,@lm,@tipstat,@ordonare,
		@grupamunca,@grpmexcep,0,0,0,0,@lunaalfa,@restplpoz) 

		if exists (select 1 from antform where Tip_formular='6' 
			and (clfrom like '% flutur %' or clfrom like '% flutur,%')
			and numar_formular=@formular)
			if exists(select * from sysobjects where name='ptFluturasiSP' and type='P')
				exec ptFluturasiSP @cTerm=@utilizator
			else 
    			exec ptFluturasi @cTerm=@utilizator, @sesiune=@sesiune	/**	Luci Maier: se executa doar daca am nevoie de date din tabela flutur */

		set @numefisier='Flutur_'+ISNULL(rtrim(@tip),'')+(case when @clfrom<>'Raport' then '.doc' else '' end)    	
    --	declare @DelayLength char(8)= '00:00:01'
	--	WAITFOR delay @DelayLength
		set @paramXmlString= (select @tip as tip, @formular as nrform,0 as scriuavnefac,
		@numefisier as numefisier, (case when @CLFrom='Raport' then @caleRaport end) as caleRaport, 
		convert(char(10),@dataSus,101) as data, convert(char(10),@dataSus,101) as datasus, @marca as numar, @marca as marca, @lm as locm, 
		@functie as Cod_gestiune, @card as Cod_tert, '' as factura, convert(char(10),@dataJos,101) as data_facturii, @lm as loc_munca, 
		@inXML as inXML, @debug as debug, 0 as faraMesaj for xml raw)
	
		exec wTipFormular @sesiune=@sesiune, @parXML=@paramXmlString
		delete from avnefac where terminal=@utilizator
	End	
----------------------------- formular pentru trimis fluturasii pe email -----------------------------
--	se parcurg salariatii care au completat campul email din infopers, in conditiile filtrelor, si fiecare document rezultat este trimis pe email
	if @tipoperatie=1
	Begin
		declare @cmarca char(6), @nume varchar(50), @email varchar(50), @parolaFlutEmail varchar(50), 
			@gfetch int, @EmailuriInGrup int, @Contor_email int
		set @EmailuriInGrup=dbo.iauParL('PS','FLEMGRUP')
		set @Contor_email=0
			
		declare tmpflut cursor for
		select a.marca, p.nume, isnull(i.email,''), isnull(dbo.iauExtinfopVal (a.Marca, 'PAROLAFLUT'),'') 
--	informatia din extinfop va fi utilizata daca se va dori arhivarea documentului (7z) cu parola (GrupSapte a cerut in ASiSplus)
		from net a
			left outer join personal p on a.marca=p.marca
			left outer join infopers i on a.marca=i.marca
			left outer join istpers ip on a.data=ip.data and a.marca=ip.marca
		where a.data=@dataSus and (@marca='' or a.marca=@marca) and (@lm='' or a.loc_de_munca=@lm) 
			and (@sirmarci='' or charindex(','+rtrim(ltrim(a.marca))+',',@sirmarci)>0) 
			and (@functie='' or ip.Cod_functie=@functie) and isnull(i.email,'')<>''

		open tmpflut
		fetch next from tmpflut into @cmarca, @nume, @email, @parolaFlutEmail
		set @gfetch=@@fetch_status
		While @gfetch = 0 
		Begin
			delete from avnefac where terminal=@utilizator
			insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,Contractul,Data_facturii,Loc_munca,Comanda,
				Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22,Cont_beneficiar,Discount) 
			values (@utilizator,'1','FS',@cmarca,'',@dataSus,'','',@utilizator, @dataJos,'','',@ordonare,'',0,0,0,0,0,@lunaalfa,0) 
	
			if exists (select 1 from antform where Tip_formular='6' 
				and (clfrom like '% flutur %' or clfrom like '% flutur,%')
				and numar_formular=@formular)
    			exec ptFluturasi @cTerm=@utilizator, @sesiune=@sesiune	/**	Luci Maier: se executa doar daca am nevoie de date din tabela flutur */

			set @numefisier='Flutur_'+ISNULL(rtrim(@tip)+rtrim(@cmarca),'')+(case when @clfrom<>'Raport' then '.doc' else '' end)
			set @paramXmlString= (select @tip as tip, @formular as nrform, 
				@numefisier as numefisier, @numefisier as numeFisier, (case when @CLFrom='Raport' then @caleRaport end) as caleRaport, 
				0 as scriuavnefac, convert(char(10),@dataSus,101) as data, convert(char(10),@dataSus,101) as datasus, @cmarca as numar, @cmarca as marca, @lm as locm, 
				'' as Cod_gestiune, '' as Cod_tert, '' as factura, @dataJos as data_facturii, '' as loc_munca, 
				0 as inXML, @debug as debug, 1 as faraMesaj, 1 as faraMesaje for xml raw)
			if @CLFrom='Raport'
				exec wExportaRaport @sesiune=@sesiune, @parXML=@paramXmlString
			else 
				exec wTipFormular @sesiune=@sesiune, @parXML=@paramXmlString
			delete from avnefac where terminal=@utilizator
			
			set @Contor_email=@Contor_email+1
--	trimitere email			
			set @file_attachments=RTRIM(@calefisier)+RTRIM(@numefisier)+(case when @CLFrom='raport' then '.PDF' else '' end)
			declare @subject varchar(200)
			set @subject='Fluturas salarii luna '+rtrim(@lunaalfa)+' '+CONVERT(char(4),@an)
			if @textemail='' set @textemail=@subject
			exec msdb..sp_send_dbmail @Profile_name=@profile_name, @recipients=@email, @subject=@subject, @body=@textemail, @file_attachments = @file_attachments
			
--	Am pus intariere la fiecare 10 mail-uri pentru a nu fi interpretate ca spam
			if @EmailuriInGrup=1 and @Contor_email % 10=0
				waitfor delay '00:00:35'

-- sterg fisierul generat; se va activa dupa ce frame-ul va stii sa nu deschida documentul. Acuma stie Frame-ul daca se lucreaza cu wExportaRaport.
			if @CLFrom='raport'
			begin
				declare @cmdShellCommand varchar(4000), @raspunsCmd int
				if object_id('tempdb..#raspCmdShell') is not null drop table #raspCmdShell
				CREATE TABLE #raspCmdShell(raspunsCmdShell Varchar(MAX))
				set @cmdShellCommand = 'del /S /Q "'+@file_attachments+'"'
				insert #raspCmdShell
				exec @raspunsCmd = xp_cmdshell @cmdShellCommand
			end

			fetch next from tmpflut into @cmarca, @nume, @email, @parolaFlutEmail
			set @gfetch=@@fetch_status
		End
		select 'S-au trimis pe email fluturasii de salarii pentru luna '+rtrim(@lunaalfa)+' '+convert(char(4),@an)+'!' as textMesaj,
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	End
end try

begin catch
	set @mesaj = '(wOPGenFluturasi) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

begin try 
	if OBJECT_ID('tempdb..#raspCmdShell') is not null
		drop table #raspCmdShell
	declare @cursorStatus int
	set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='tmpflut' and session_id=@@SPID )
	if @cursorStatus=1 
		close tmpflut
	if @cursorStatus is not null 
		deallocate tmpflut
end try 
begin catch end catch

