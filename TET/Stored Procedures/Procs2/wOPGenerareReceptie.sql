/***--
procedura folosita pentru generarea de receptii din dispozitii de receptii.
In principiu, chiar daca nu e des intalnit, din o dispozitie de receptie se pot genera mai multe receptii 
pe facturi/terti diferiti, sau alte criterii.

--***/
CREATE PROCEDURE wOPGenerareReceptie @sesiune varchar(50), @parXML xml
AS
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareReceptieSP')
begin
	declare @returnValue int
	exec @returnValue = wOPGenerareReceptieSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(1000), @iddisp int, @gest_ok varchar(30), @gest_sparturi varchar(30), @gest_lipsa varchar(30), @cu_inserare_lipsa bit,
		@xml xml, @tert varchar(50), @xmlTemp xml, @dataDebug datetime, @crsPoz cursor, @cod varchar(50), @cantitate varchar(50), @gestiune varchar(50), @pret varchar(50),
		@detaliiOperatie xml, @lm varchar(50),@cu_actualizare_pretvanzare bit,
		@data_receptie datetime, @data_facturii datetime, @factura varchar(20),@numar varchar(8)
 
begin try
	set @dataDebug=GETDATE()
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	exec wJurnalizareOperatie @sesiune,@parXML,'wOPGenerareReceptie'
	
	set @detaliiOperatie=(select top 1 @parXML.query('/*/detalii/row'))
	
	/*Preia parametrii XML trimisi */
	select	@iddisp	= @parXML.value('(/*/@iddisp)[1]', 'int'),
			@gest_ok = isnull(@detaliiOperatie.value('(/row/@gestiune)[1]', 'varchar(13)'), ''), -- gestiunea receptiei
			@gest_sparturi = isnull(@detaliiOperatie.value('(/row/@gestiune_sparturi)[1]', 'varchar(13)'), ''), -- gestiune unde se receptioneaza produsele sparte
			@gest_lipsa = isnull(@detaliiOperatie.value('(/row/@gestiune_lipsa)[1]', 'varchar(13)'), ''), -- gestiune unde se insereaza diferentele dintre ce e operat si ce e scanat (diferente scriptic-faptic)
			@cu_inserare_lipsa = isnull(@detaliiOperatie.value('(/row/@cu_inserare_lipsa)[1]', 'bit'),0), -- daca se trimie '1', se insereaza si in gestiunea lipsuri
			@tert = isnull(@detaliiOperatie.value('(/row/@tert)[1]', 'varchar(13)'), ''),
			@lm = isnull(@detaliiOperatie.value('(/row/@lm)[1]', 'varchar(13)'), ''),
			@cu_actualizare_pretvanzare = isnull(@detaliiOperatie.value('(/row/@cu_actualizare_pretvanzare)[1]', 'bit'),0), -- daca se trimie '1', se actualizeaza pretul de vanzare
			@data_facturii = isnull(@parXML.value('(/parametri/@data_facturii)[1]', 'datetime'), ''),
			@factura = isnull(@detaliiOperatie.value('(/row/@factura)[1]', 'varchar(20)'), ''),
			@data_receptie = isnull(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),
			@numar = isnull(@parXML.value('(/parametri/@numar)[1]', 'varchar(8)'), '')
	
	/*select @data_receptie
	raiserror('as',11,1)*/
	/*Daca nu s-a selectat nici un document nu se poate efectua operatia. */
	if isnull(@iddisp,0)=0
		raiserror('Va rugam sa selectati dispozitia de receptie.', 11, 1)
	
	/*Daca documentul a fost finalizat nu se mai poate opera */
	if (select max(a.stare) from AntDisp a where a.idDisp = @iddisp) = 'Finalizat'
		raiserror('Documentul a fost deja finalizat.', 11, 1)
	
	if (select max(a.stare) from AntDisp a where a.idDisp = @iddisp) <> 'scanata '
		raiserror('Doar din dispozitiile in stare ''scanata'' se pot genera receptii.', 11, 1)
	
	if not exists (select * from terti where Subunitate='1' and tert=@tert)
		raiserror('Tertul receptiei nu este completat. Completati tertul in antet sau pe o pozitie',11,1)
	
	declare @pozitii table (idpoz int, cod varchar(20), cant_operata decimal(12,3), cant_ok decimal(12,3), cant_sparta decimal(12,3), cant_lipsa decimal(12,3), 
		pret decimal(12,3), cotatva float, pretvanzare float, pretamanunt float, categpret int)
	-- citesc cantitatile din XML(cantitatile operate de utilizator)
	insert @pozitii(idpoz, cod, cant_operata, cant_ok, cant_sparta, cant_lipsa, pret, cotatva, pretvanzare, pretamanunt, categpret)
	SELECT 
		xA.linie.value('(@idpoz)[1]', 'int') idpoz, 
		xA.linie.value('(@cod)[1]', 'varchar(20)') cod, 
		xA.linie.value('(@cant_op)[1]', 'float') cant_operata,
		xA.linie.value('(@cant_ok_de_scris)[1]', 'float') cant_ok,
		xA.linie.value('(@cant_sparta_de_scris)[1]', 'float') cant_sparta,
		0 cant_lipsa,
		xA.linie.value('(@pret)[1]', 'float') pret,
		
		--date necesare pentru actualizare pret_vanzare
		
		xA.linie.value('(@cotatva)[1]', 'float') cotatva,
		xA.linie.value('(@pretvanzare)[1]', 'float') pretvanzare,
		xA.linie.value('(@pretamanunt)[1]', 'float') pretamanunt,
		xA.linie.value('(@categpret)[1]', 'float') categpret
	FROM @parXML.nodes('parametri/DateGrid/row') xA(linie)
	
	if @cu_inserare_lipsa=1
		update @pozitii set cant_lipsa=cant_operata-cant_ok-cant_sparta
	
	-- daca nu sunt linii, nu avem ce trimite la wScriuPozdoc
	-- eventual aici am putea trata sa se trimita toate pozitiile operate.
	if not exists (select * from @pozitii)
		raiserror('Dispozitia nu are nicio pozitie care trebuie receptionata.',11,1)
	
	-- daca toate liniile sunt nule, nu avem ce sa scriem in pozdoc
	if not exists (select * from @pozitii where cant_ok<>0 or cant_sparta<>0 or cant_lipsa<>0)
		raiserror('Toate pozitiile au cantitate operata nula. Nu am gasit nicio pozitie de receptionat.',11,1)-- poate ca ar trebui gasit un mesaj mai frumos :)
	
	-- validare completare gestiune (daca e cazul)
	if exists(select * from @pozitii where cant_ok<>0) and @gest_ok=''
		raiserror('Gestiunea receptiei nu este completata.',11,1)
	
	-- validare completare gestiune sparturi(daca e cazul)
	if exists(select * from @pozitii where cant_sparta<>0) and @gest_sparturi=''
		raiserror('Gestiunea pentru produsele sparte nu este completata.',11,1)
	
	-- validare completare gestiune lipsuri(daca e cazul)
	if @cu_inserare_lipsa=1 and exists(select * from @pozitii where cant_lipsa<>0) and @gest_lipsa=''
		raiserror('Gestiunea pentru produsele lipsa nu este completata.',11,1)
	
	/*
		formez aici toate liniile de trimis la pozdoc.
		Se scriu mai multe lnii pentru fiecare cod, una pentru fiecare tip de cantitate(si astfel alta gestiune).
	*/
	create table #poz(cod varchar(20), cantitate decimal(12,3), gestiune varchar(50), pret decimal(12,3), idpoz int,
		pretvanzare float, pretamanunt float, categpret int, xmlCol xml)
	
	insert #poz(cod, cantitate, gestiune, pret, idpoz, pretvanzare, pretamanunt, categpret)
	select p.cod, p.cant_ok, @gest_ok, pret, p.idpoz, p.pretvanzare, p.pretamanunt, p.categpret
		from @pozitii p
		where p.cant_ok<>0
	union all
	select p.cod, p.cant_sparta, @gest_sparturi, pret, p.idpoz, p.pretvanzare, p.pretamanunt, p.categpret
		from @pozitii p
		where p.cant_sparta<>0
	union all
	select p.cod, p.cant_lipsa, @gest_lipsa, pret, p.idpoz, p.pretvanzare, p.pretamanunt, p.categpret
		from @pozitii p
		where p.cant_lipsa<>0
	
	declare @pretvanzare float, @pretamanunt float, @categpret int, @pX xml
	set @crsPoz = cursor for 
		select po.detalii, p.gestiune, p.cod, LTRIM(str(p.cantitate,12,2)), LTRIM(str(p.pret,12,2)),
			ltrim(str(p.pretvanzare,12,5)), ltrim(str(p.pretamanunt,12,5)), ltrim(str(p.categpret))  
			from #poz p, PozDispOp po
			where p.idpoz=po.idPoz
	
	open @crsPoz
	fetch next from @crsPoz into @xmlTemp, @gestiune, @cod, @cantitate, @pret, @pretvanzare, @pretamanunt, @categpret
	while @@FETCH_STATUS=0
	begin
		if isnull(convert(varchar(max),@xmlTemp),'')=''
			set @xmlTemp='<row />'
		
		if @xmlTemp.exist('/row[1]/@gestiune')=0
			set @xmlTemp.modify('insert attribute gestiune {sql:variable("@gestiune")} into /row[1]')
		if @xmlTemp.exist('/row[1]/@cod')=0
			set @xmlTemp.modify('insert attribute cod {sql:variable("@cod")} into /row[1]')
		if @xmlTemp.exist('/row[1]/@cantitate')=0
			set @xmlTemp.modify('insert attribute cantitate {sql:variable("@cantitate")} into /row[1]')
		if @xmlTemp.exist('/row[1]/@pret')=0
			set @xmlTemp.modify('insert attribute pvaluta {sql:variable("@pret")} into /row[1]')
		if @xmlTemp.exist('/row[1]/@tip')=0
			set @xmlTemp.modify('insert attribute tip {"RM"} into /row[1]')
		
		update #poz
			set xmlCol=@xmlTemp
		where current of @crsPoz
		
		if @cu_actualizare_pretvanzare=1
		begin
			/* setare noul pret*/
			set @pX=(select @cod as '@cod',
				(select 'PR' as '@tip',convert(varchar,@categpret) as '@catpret','1' as '@tippret', ltrim(str(@pretamanunt,12,5)) as '@pret_cu_amanuntul',
					CONVERT(char(10),getdate(),101) as '@data_inferioara',
					
					convert(varchar,@categpret) as '@o_categorie','1' as '@o_tippret', CONVERT(char(10),getdate(),101) as '@o_data_inferioara',
					
					1 as '@update'
				for xml path,type)
			for xml path,type)	
			
			exec wScriuPreturiNomenclator @sesiune=@sesiune,@parXML=@pX
		end
		fetch next from @crsPoz into @xmlTemp, @gestiune, @cod, @cantitate, @pret, @pretvanzare, @pretamanunt, @categpret
	end
	if CURSOR_STATUS('variable','@crsPoz') >= 0
		close @crsPoz
	if CURSOR_STATUS('variable','@crsPoz') >= -1
		deallocate @crsPoz
--raiserror ('aiic',11,1)	
	alter table #poz 
		drop column cod, cantitate, gestiune, pret, idpoz
	
	if @lm=''
		set @lm=isnull((select max(loc_de_munca) from gestcor where gestiune=@gestiune), '')
	if @lm=''
	    set @lm =isnull((select max(loc_munca) from infotert where subunitate = '1' and identificator <> '' and tert = @tert), '')
	
	declare @NrDocPrimit varchar(20), @idPlajaPrimit int
	if ISNULL(@numar,'')=''
	begin		
		set @xmlTemp=(select 'RM' tip, @userASiS utilizator, @lm lm for xml raw)
		exec wIauNrDocFiscale @parXML=@xmlTemp, @NrDoc=@NrDocPrimit output,@Numar= @NrDocPrimit output,@idPlaja=@idPlajaPrimit output
	end
	else --daca numarul de receptie a fost generat in momentul deschiderii dispozitiei de receptie(din motive de refresh(solutie temporara)
		set @NrDocPrimit=@numar
	
	if @NrDocPrimit is null
		raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
	
	-- formare XML cu date care trebuie scrise in pozdoc.	
	set @xml=(select CONVERT(char(10),@data_receptie,101) as data, @tert as tert, 'RM' as tip, @NrDocPrimit as numar,
				(select xmlCol.query('.')  from #poz p for xml path(''),type)
		for xml raw)
	
	-- adaug atributele din detaliiXml din antet
	set @xmlTemp=(select top 1 a.detalii from AntDisp a where idDisp=@iddisp)
	if @xmlTemp is not null
		exec adaugaAtributeXml @xmlSursa=@xmlTemp, @xmlDest=@xml output
	
	-- adaug atributele din detaliile operatiei.
	if @detaliiOperatie is not null
		exec adaugaAtributeXml @xmlSursa=@detaliiOperatie, @xmlDest=@xml output
	
	--select @xml
	--raiserror('in lucru',11,1)
	exec wScriuPozdoc @sesiune=@sesiune, @parXml=@xml output
	
	
	/* salvare date pentru identificare receptie generata din dispozitie*/
	declare @detalii xml, @numar_receptie varchar(8)
	set @detalii=(select detalii from AntDisp where idDisp=@iddisp)
	
	
	--select @numar_receptie= isnull(@xml.value('(/*/@numar)[1]', 'varchar(8)'),''),
		--@data_receptie= isnull(@xml.value('(/*/@data)[1]', 'datetime'),'')	

	if @detalii.value('(/row/@numar_receptie)[1]', 'varchar(8)') is not null                          
		set @detalii.modify('replace value of (/row/@numar_receptie)[1] with sql:variable("@NrDocPrimit")') 
	else
		set @detalii.modify ('insert attribute numar_receptie{sql:variable("@NrDocPrimit")} into (/row)[1]') 
	
	if @detalii.value('(/row/@data_receptie)[1]', 'datetime') is not null                
		set @detalii.modify('replace value of (/row/@data_receptie)[1] with sql:variable("@data_receptie")') 
	else
		set @detalii.modify ('insert attribute data_receptie{sql:variable("@data_receptie")} into (/row)[1]') 	
	
	update AntDisp set detalii=@detalii where idDisp=@iddisp	
		
end try

begin catch
	if @NrDocPrimit is not null and not exists(select 1 from docfiscalerezervate where idPlaja=@idPlajaPrimit)
			insert into docfiscalerezervate(idPlaja,numar,expirala) values (@idPlajaPrimit,@NrDocPrimit,getdate())
	set @mesaj = ERROR_MESSAGE()+' (wOPGenerareReceptie)'
end catch

if OBJECT_ID('tempdb..#poz') is not null
	drop table #poz 
		
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)

select DATEDIFF(millisecond, @dataDebug, getdate())

/*
select * from AntDisp
select * from PozDispOp
-- update pozdispop set detalii='<row contract="c2" />' where idpoz=18
--delete from pozdispop where idpoz > 1
select p.* from pozCon p where tip = 'fc' and subunitate = '1'
select * from pozdoc where subunitate = '1' and tip = 'rm'
*/

/*

declare @p2 xml
set @p2=convert(xml,N'
<parametri iddisp="2" descriere="una" stare="Scanata" tip="IN" cu_inserare_lipsa="1" tipMacheta="D" codMeniu="DR" TipDetaliere="IN" subtip="GR" o_iddisp="2" o_descriere="una" o_stare="Scanata" o_tip="IN" o_cu_inserare_lipsa="1" o_tipMacheta="D" o_codMeniu="DR" o_TipDetaliere="IN" o_subtip="GR" update="1" gestiune="1" gestiune_sparturi="2" gestiune_lipsa="8" data_receptie="09/04/2012" tert="103" lm="1" factura="123123" data_facturii="09/04/2012">
	<o_DateGrid>
		<row idpoz="7" cod="1001" denumire="(1001) SALTEA CONFORT 1900 X 1600 \ (SLC)" pret="10.00" cant_op="1.00" cant_scan_ok="0.00" cant_scan_spart="1.00" cant_ok_de_scris="0.00" cant_sparta_de_scris="1.00" />
		<row idpoz="8" cod="PERM" denumire="(PERM) PERMAMENT PAR SCURT" pret="1.00" cant_op="2.00" cant_scan_ok="0.00" cant_scan_spart="1.00" cant_ok_de_scris="0.00" cant_sparta_de_scris="1.00" />
		<row idpoz="9" cod="1003" denumire="(1003) HDF - NUC FRANCEZ H 5773 EGGER WTP" pret="15.00" cant_op="10.00" cant_scan_ok="10.00" cant_scan_spart="0.00" cant_ok_de_scris="10.00" cant_sparta_de_scris="0.00" />
		<row idpoz="10" cod="1033" denumire="(1033) MANER P RELING 8016 CIRES CAPAT CR MAT L=172/160MM \(SALICE)" pret="3.00" cant_op="5.00" cant_scan_ok="2.00" cant_scan_spart="3.00" cant_ok_de_scris="2.00" cant_sparta_de_scris="3.00" />
		<row idpoz="11" cod="1" denumire="(1) PRODUS TEST 1" pret="5.00" cant_op="2.00" cant_scan_ok="0.00" cant_scan_spart="2.00" cant_ok_de_scris="0.00" cant_sparta_de_scris="2.00" />
	</o_DateGrid>
	<DateGrid>
		<row idpoz="7" cod="1001" denumire="(1001) SALTEA CONFORT 1900 X 1600 \ (SLC)" pret="10.00" cant_op="1.00" cant_scan_ok="0.00" cant_scan_spart="1.00" cant_ok_de_scris="0.00" cant_sparta_de_scris="1.00" />
		<row idpoz="8" cod="PERM" denumire="(PERM) PERMAMENT PAR SCURT" pret="1.00" cant_op="2.00" cant_scan_ok="0.00" cant_scan_spart="1.00" cant_ok_de_scris="0.00" cant_sparta_de_scris="1.00" />
		<row idpoz="9" cod="1003" denumire="(1003) HDF - NUC FRANCEZ H 5773 EGGER WTP" pret="15.00" cant_op="10.00" cant_scan_ok="10.00" cant_scan_spart="0.00" cant_ok_de_scris="10.00" cant_sparta_de_scris="0.00" />
		<row idpoz="10" cod="1033" denumire="(1033) MANER P RELING 8016 CIRES CAPAT CR MAT L=172/160MM \(SALICE)" pret="3.00" cant_op="5.00" cant_scan_ok="2.00" cant_scan_spart="3.00" cant_ok_de_scris="2.00" cant_sparta_de_scris="3.00" />
		<row idpoz="11" cod="1" denumire="(1) PRODUS TEST 1" pret="5.00" cant_op="2.00" cant_scan_ok="0.00" cant_scan_spart="2.00" cant_ok_de_scris="0.00" cant_sparta_de_scris="2.00" />
	</DateGrid>
</parametri>
')
exec wOPGenerareReceptie @sesiune='C714917D70E37',@parXML=@p2


*/
