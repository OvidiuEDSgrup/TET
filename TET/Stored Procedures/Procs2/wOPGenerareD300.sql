--***
Create procedure wOPGenerareD300 @sesiune varchar(50), @parXML xml
as

declare @subtip varchar(2), @codfiscal varchar(20), @tipdecl varchar(1), @numedecl varchar(150), @prendecl varchar(50), @functiedecl varchar(50), 
	@pro_rata int, @bifa_interne int, @ramburstva int, @bifa_cereale int, @optiunigenerare int, 
	@calefisier varchar(300), @data datetime, @lunaalfa varchar(15), @luna int, @an int, --@dataj datetime, @datas datetime, 
	@userASiS varchar(10), @nrLMFiltru int, @LMFiltru varchar(9), @iDoc INT

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareD300'

set @subtip = ISNULL(@parXML.value('(/parametri/@subtip)[1]', 'varchar(2)'), '')
set @tipdecl = ISNULL(@parXML.value('(/parametri/@tipdecl)[1]', 'varchar(1)'), '')
set @numedecl = ISNULL(@parXML.value('(/parametri/@numedecl)[1]', 'varchar(150)'), '')
set @prendecl = ISNULL(@parXML.value('(/parametri/@prendecl)[1]', 'varchar(50)'), '')
set @functiedecl = ISNULL(@parXML.value('(/parametri/@functiedecl)[1]', 'varchar(50)'), '')
set @pro_rata = ISNULL(@parXML.value('(/parametri/@prorata)[1]', 'int'), 100)
set @bifa_interne = ISNULL(@parXML.value('(/parametri/@interne)[1]', 'int'), 0)
set @ramburstva = ISNULL(@parXML.value('(/parametri/@ramburstva)[1]', 'int'), 0)
set @optiunigenerare = ISNULL(@parXML.value('(/parametri/@optiunigenerare)[1]', 'int'), 0)

exec luare_date_par 'AR', 'CALEFORM', 0, 0, @calefisier output
select @calefisier=rtrim(@calefisier)
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
begin
	set @data=dbo.bom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
	set @data=(case @tipdecl when 'T' then Dateadd(MONTH,-(Month(@data)-1) % 3,@data) when 'S' then 
		Dateadd(month,-(Month(@data)-1) % 6,@data) when 'A' then Dateadd(month,1-Month(@data),@data) 
		else @data end)
end
select @lunaalfa=LunaAlfa from fCalendar(@data,@data)
select @nrLMFiltru=count(1), @LMFiltru=isnull(max(Cod),'') from LMfiltrare where utilizator=@userASiS

begin try  
	if not exists (select * from sysobjects where name ='deconttva')
		raiserror('Nu exista tabela deconttva. Rulati fisierul +tabele din folderul AS!' ,16,1)

	if @luna=0 or @an=0
		raiserror('Alegeti luna si anul!' ,16,1)
			
	if rtrim(left(@calefisier,4))='' --'\300'
		raiserror('Completati cale fisier formulare (AR,CALEFORM) in parametrii!' ,16,1)
			
	if @numedecl='' or @prendecl='' or @functiedecl=''
		raiserror('Completati nume, prenume si functie declarant!' ,16,1)

	if @subtip in ('ED'/*,'GD'*/)
	Begin
--	citire date din gridul de operatii
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		IF OBJECT_ID('tempdb..#xmldeconttva') IS NOT NULL
			DROP TABLE #xmldeconttva

		SELECT isnull(data,datalunii) as data, rand_decont, valoare, tva
		INTo #xmldeconttva
		FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
		WITH
		(
			data datetime '@data'
			,datalunii datetime '@datalunii'
			,rand_decont varchar(20) '@randdecont'
			,valoare FLOAT '@valoare'
			,tva FLOAT '@tva'
		)
		EXEC sp_xml_removedocument @iDoc 

--	actualizez datele din tabela deconttva cu valorile din grid (daca s-au modificat)
		update d set valoare=x.valoare, TVA=x.tva 
		from deconttva d, #xmldeconttva x
		where d.Data=x.data and d.Rand_decont=x.Rand_decont
	End
	else 
	Begin
		exec Declaratia300 @data=@data, @nume_declar=@numedecl, @prenume_declar=@prendecl, @functie_declar=@functiedecl, 
			@bifa_interne=@bifa_interne, @pro_rata=@pro_rata, @ramburstva=@ramburstva, 
			@caleFisier=@calefisier, @dinRia=1, @tip_D300=@tipdecl, @OptiuniGenerare=@optiunigenerare

		select @numedecl=rtrim(@numedecl)+' '+@prendecl--, @calefisier=LEFT(@calefisier,CHARINDEX('300',@calefisier)-1)
		exec setare_par 'GE', 'NDECLTVA', 'Nume pers. declaratie TVA', 0, 0, @numedecl
		exec setare_par 'GE', 'FDECLTVA', 'Functie pers. declaratie TVA', 0, 0, @functiedecl
		exec setare_par 'GE', 'PRORATA', 'Pro rata de deducere %', 0, @pro_rata, ''
		exec setare_par 'GE', 'D300MSINT', 'Metoda simplificata-op.interne', @bifa_interne, 0, ''
	
		select 'S-a efectuat generarea decontului de TVA (declaratia 300) pt. luna '+rtrim(@lunaalfa)+' anul '+convert(char(4),year(@data))+'!' as textMesaj, 
			'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	End
	BEGIN TRY 
		IF OBJECT_ID('#xmldeconttva') is not null DROP TABLE #xmldeconttva
	END TRY 
	BEGIN CATCH END CATCH   

end try  

begin catch
	declare @eroare varchar(254)
	set @eroare='Procedura wOPGenerareD300 (linia '+convert(varchar(20),ERROR_LINE())+'): '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1)
end catch
