--***
create procedure [wStergPozdoc] @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml ,@serie varchar(20),@prop1 varchar(20),@prop2 varchar(20),@cod varchar(20),@tip varchar(2),@update bit,@subtip varchar(2),
		@subunitate varchar(9),@numar varchar(20),@data datetime,@numar_pozitie int	,@docXMLIaPozdoc xml,@cantitate float,@gest varchar(9),@cod_intrare varchar(13),
		@userAsis varchar(13),@tert varchar(13), @tip_doc varchar(2), @idpromotie int	


begin try
begin transaction
	if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPozdocSP')
		exec wStergPozdocSP @sesiune, @parXML output


	if exists (select 1 from sysobjects where [type]='P' and [name]='wStergMFdinCG')
	Begin
		-- inserez atribut stergMF in parXML pentru sti in procedura wValidareMFdinCG ca este vorba de stergere.
		-- Procedura wValidareMFdinCG se apeleaza si din wPregatireMFdinCG (apelata din wScriuPozdoc) si din wStergMFdinCG.
		declare @stergMF int
		set @stergMF=1
		if @parXML.value('(/*/*/@stergMF)[1]','int') IS NULL
			set @parXML.modify ('insert attribute stergMF {sql:variable("@stergMF")} into (/row/row)[1]')
		else 
			set @parXML.modify('replace value of (/row/row/@stergMF)[1] with sql:variable("@stergMF")')

		exec wStergMFdinCG @sesiune, @parXML output
	End

	select
		 @subunitate=isnull(@parXML.value('(/row/@subunitate )[1]', 'varchar(9)'), ''),
		 @tip=isnull(@parXML.value('(/row/@tip )[1]', 'varchar(2)'), ''),	
		 @numar=isnull(@parXML.value('(/row/@numar )[1]', 'varchar(20)'), ''),
		 @tert=isnull(@parXML.value('(/row/@tert )[1]', 'varchar(13)'), ''),
		 @gest=isnull(@parXML.value('(/row/@gestiune )[1]', 'varchar(9)'), ''),	 
		 @data=isnull(@parXML.value('(/row/@data )[1]', 'datetime'), '1901-01-01'),
		 @numar_pozitie=isnull(@parXML.value('(/row/@numarpozitie )[1]', 'int'), ''),
	 
		 ---folosite exclusiv pentru lucrul pe serii
		 @cod_intrare=isnull(isnull(@parXML.value('(/row/row/row/@codintrareS )[1]', 'varchar(13)'), 
									@parXML.value('(/row/row/@codintrareS )[1]', 'varchar(13)')),''),
		 @prop1=isnull(@parXML.value('(/row/row/@prop1 )[1]', 'varchar(20)'), ''),
		 @prop2=isnull(@parXML.value('(/row/row/@prop2 )[1]', 'varchar(20)'), ''),
		 @cod=isnull(@parXML.value('(/row/row/@cod )[1]', 'varchar(20)'), ''),
		 @subtip=isnull(@parXML.value('(/row/row/@subtip )[1]', 'varchar(2)'), ''),	
		 @serie=isnull(@parXML.value('(/row/row/row/@serie )[1]', 'varchar(20)'), ''),
		 @idPromotie = @parXml.value('(//@idpromotie)[1]','int')

	-- variabila folosita pt. filtrarea tipului de document in tabelele doc/pozdoc, pentru ca sa nu facem multe case-uri
	set @tip_doc= (case when @tip in ('RC','RA','RF') then 'RM' when @tip in ('AA','AB') then 'AP' else @tip end)
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	IF @idPromotie IS NOT NULL
	begin
		set @parXML.modify('insert attribute sterg {"1"} into /row[1]')
		set @parXML.modify('insert attribute _document {"aviz"} into (/row)[1]')
		exec wOPTrateazaPromotie @sesiune=@sesiune, @parXML=@parXML OUTPUT
		exec wIaPozdoc @sesiune=@sesiune, @parXML=@parXML

		commit tran
		return
	end

	if @serie=''
		set @serie=(case when @prop1<>'' and @prop2<>'' then rtrim(ltrim(@prop1))+','+RTRIM(ltrim(@prop2))when  @prop1<>'' and @prop2='' then @prop1 else''end)	
	
	----Daca se sterge o factura generata din penalitati se apeleaza procedura care trece penalitatile in stare nefacturat----
	IF EXISTS(SELECT name FROM sys.tables WHERE name = 'penalizarifact') and @tip='AS'--daca exista tabela specifica de penalitai si dobanzi
		if exists (select 1 from sysobjects where [type]='P' and [name]='wUpdateStergerePenDob')
		begin
			exec wUpdateStergerePenDob @sesiune,@parXML
		end
		
	if @subtip='SE' --suntem pe linie de serie
	begin
		delete from pdserii where Subunitate=@subunitate and tip=@tip and Numar=@numar and data=@data 
							  and cod=@cod and Numar_pozitie=@numar_pozitie and Cod_intrare=@cod_intrare and Serie=@serie--stergere serie din pdserii
							  
		set @Cantitate =(select SUM(cantitate) from pdserii where tip=@Tip and Numar=@Numar and data=@Data and Gestiune=@Gest and cod=@Cod 
														  and Cod_intrare=@cod_intrare and Numar_pozitie=@numar_pozitie)--recalculam cantitatea din pdserii pentru acesta pozitie din pozdoc
		
		if @cantitate>0.001--daca cantitatea este mai mare de 0=> mai avem si alte serii pe aceasta pozitie din pozdoc, deci reglam cantitatea de pe ea
			update pozdoc set cantitate=@cantitate,	utilizator=@userAsis,data_operarii=convert(datetime,convert(char(10),getdate(),104),104),ora_operarii=RTrim(replace(convert(char(8),getdate(),108),':',''))
			where subunitate=@subunitate and tip=@Tip and numar=@Numar and data=@Data and numar_pozitie=@numar_pozitie					  
		
		else -- nu mai sunt serii pe aceasta pozitie => stergem pozitia din pozdoc
		BEGIN
			--daca exista id pe pozdoc si exista tabela LegaturiStornare
			IF EXISTS (	SELECT *FROM sys.objects WHERE NAME = 'LegaturiStornare' AND type = 'U'	) 
				AND EXISTS (SELECT 1 FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'idPozDoc')
			BEGIN 	
				--daca pozitia este pozitie sursa pentru un document storno, se returneaza mesaj de eroare
				IF EXISTS(SELECT 1 FROM pozdoc p1 INNER JOIN LegaturiStornare l1 ON l1.idSursa=p1.idPozDoc AND p1.Subunitate=@subunitate 
					AND p1.tip=@Tip AND p1.numar=@Numar AND p1.data=@Data AND p1.numar_pozitie=@numar_pozitie) 
				
					RAISERROR('Aceasta pozitie a fost stornata, trebuie sters mai intai documentul de stornare!',11,1)						
				
				ELSE /*daca pozitia care se sterge nu este o pozitie sursa pentru stornari, dar este pozitie storno, 
					se sterge legatura cu pozitia de pe care s-a facut stornare*/
					DELETE LegaturiStornare 
					FROM LegaturiStornare l 
						INNER JOIN pozdoc p ON l.idStorno=p.idPozDoc AND subunitate=@subunitate AND tip=@tip_doc AND numar=@Numar AND data=@Data AND numar_pozitie=@numar_pozitie	
			END
		
			delete from pozdoc 
			where Subunitate=@subunitate and tip=@tip_doc and Numar=@numar and data=@data and (@tip<>'RC' or jurnal='RC') and Numar_pozitie=@numar_pozitie
		
		END
	end	
		 			  
	else --suntem pe linie cu pozitie de document 
    begin	
		if (select UM_2  from nomencl where cod=@cod)='Y' and @serie<>''--daca avem serii pe acesta pozitie stergem toate seriile
		begin
			delete from pdserii where Subunitate=@subunitate and tip=@tip_doc and Numar=@numar and data=@data 
								  and cod=@cod and Numar_pozitie=@numar_pozitie and Cod_intrare=@cod_intrare
		end		
		
		--daca exista id pe pozdoc si exista tabela LegaturiStornare
		IF EXISTS (	SELECT *FROM sys.objects WHERE NAME = 'LegaturiStornare' AND type = 'U'	) 
			AND EXISTS (SELECT 1 FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'idPozDoc')
		BEGIN 	
			--daca pozitia este pozitie sursa pentru un document storno, se returneaza mesaj de eroare
			IF EXISTS(SELECT 1 FROM pozdoc p1 INNER JOIN LegaturiStornare l1 ON l1.idSursa=p1.idPozDoc AND p1.Subunitate=@subunitate 
				AND p1.tip=@Tip AND p1.numar=@Numar AND p1.data=@Data AND p1.numar_pozitie=@numar_pozitie) 
			
				RAISERROR('Aceasta pozitie a fost stornata, trebuie sters mai intai documentul de stornare aferent!',11,1)						
			
			ELSE /*daca pozitia care se sterge nu este o pozitie sursa pentru stornari, dar este pozitie storno, 
				se sterge legatura cu pozitia de pe care s-a facut stornare*/
			BEGIN	
				DELETE LegaturiStornare 
				FROM LegaturiStornare l 
					INNER JOIN pozdoc p ON l.idStorno=p.idPozDoc AND subunitate=@subunitate AND tip=@tip_doc AND numar=@Numar AND data=@Data AND numar_pozitie=@numar_pozitie	
			END			
		END
		
		delete from pozdoc where Subunitate=@subunitate and tip=@tip_doc and Numar=@numar and data=@data and (@tip<>'RC' or jurnal='RC') and Numar_pozitie=@numar_pozitie
			and @tip not in ('RP','RZ') --stergere si pozitie din pozdoc	
		 						 
	end
	
	-->in cazul in care se sterge o pozitie de pe o receptie care are prestari, se apeleaza procedura de repartizare prestari pe pozitiile ramase
	if exists (select 1 from pozdoc where tip in ('RP','RZ') and Subunitate=@subunitate and Numar=@numar and data=@data) and @tip in ('RM','RS')
	begin
		/**
			Daca este ultima pozitie de RM care "se sterge" stergem si toate prestarile care ar mai fi ramas
		*/
		IF NOT EXISTS (select 1 from pozdoc where Subunitate=@subunitate and tip=@tip and numar=@numar AND data=@data)
			delete from pozdoc where Subunitate=@subunitate and Tip in ('RP','RZ') and numar=@numar and data=@data
		else
			exec repartizarePrestariReceptii @tip, @numar, @data		
	end
	
	--daca se sterge o pozitie de pe un RM care are dvi, deschidem macheta pentru DVI pentru refacere repartizare taxe vamale
	if @tip_doc='RM' and exists(select 1 from pozdoc where Subunitate=@subunitate and tip='RM' and Numar=@numar and data=@data and isnull(Numar_DVI,'')<>'')
	begin
		DECLARE @dateInitializare XML	
		set @dateInitializare=
		(
			select convert(char(10), @data, 101) as data, @numar as numar, @tert as tert, @tip as tip
			for xml raw ,root('row')
		)
		SELECT 'Pe aceasta receptie au fost introduse taxe vamale, este necesara actualizarea lor la fiecare modificare a rezeptiei.'  nume, 'DO' codmeniu, 'D' tipmacheta, @tip tip,'DV' subtip,'O' fel,convert(char(10), @data, 101) as data, @numar as numar, @tert as tert,
	 (SELECT @dateInitializare ) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	end
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPozdocSP2')
		exec wStergPozdocSP2 @sesiune, @parXML output
		
	set @docXMLIaPozdoc = '<row subunitate="' + rtrim(@subunitate) + '" tip="' + rtrim(@tip) + '" numar="' + rtrim(@numar) + '" data="' + convert(char(10), @data, 101) +'"/>'
	exec wIaPozdoc @sesiune=@sesiune, @parXML=@docXMLIaPozdoc
			
commit transaction
end try
begin catch
   ROLLBACK TRAN
	
	declare @mesaj varchar(255)
	set @mesaj=ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)
	--select @eroare FOR XML RAW
end catch
