--***
create procedure wOPRefacereIntegritate @sesiune varchar(50), @parXML xml          
as 
begin try
declare @sub varchar(9),@lunabloc int,@anulbloc int, @databloc datetime, @userASiS varchar(10), 
	@codmeniu varchar(2),@tip_necorelatii varchar(2),@dataj datetime,@datas datetime,
	@tipdoc varchar(2),@nrdoc varchar(20),@datadoc datetime,@cont varchar(40),@tert varchar(20),
	/*@tipfact varchar(1),@fact varchar(20),@tipefect varchar(1),@efect varchar(20),@decont varchar(20),
	@marca varchar(20),@tipgest varchar(1),*/@gest varchar(20),@cod varchar(20),@eroare varchar(254), @subunitate varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

select @codmeniu=isnull(@parXML.value('(/parametri/@codMeniu)[1]','varchar(2)'),''), 
	@tip_necorelatii=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''), 
	@dataj=ISNULL(@parXML.value('(/parametri/@datajos)[1]', 'datetime'), '01/01/1901'),
	@datas=ISNULL(@parXML.value('(/parametri/@datasus)[1]', 'datetime'), '01/01/1901'),
	@tipdoc=ISNULL(@parXML.value('(/parametri/@tip_document)[1]', 'varchar(2)'), ISNULL(@parXML.value('(/parametri/@tipfact)[1]', 'varchar(2)'), '')), 
	@nrdoc=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ISNULL(@parXML.value('(/parametri/@factura)[1]', 'varchar(20)'), '')),     
	@datadoc=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '01/01/1901'),
	@cont=ISNULL(@parXML.value('(/parametri/@cont)[1]', 'varchar(40)'), ''),     
	@tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), ''),     
	/*@tipfact=ISNULL(@parXML.value('(/parametri/@tipfact)[1]', 'varchar(1)'), ''), 
	@fact=ISNULL(@parXML.value('(/parametri/@factura)[1]', 'varchar(20)'), ''),
	@tipefect=ISNULL(@parXML.value('(/parametri/@tipefect)[1]', 'varchar(1)'), ''), 
	@efect=ISNULL(@parXML.value('(/parametri/@efect)[1]', 'varchar(20)'), ''),
	@decont=ISNULL(@parXML.value('(/parametri/@decont)[1]', 'varchar(20)'), ''),
	@marca=ISNULL(@parXML.value('(/parametri/@marca)[1]', 'varchar(20)'), ''), 
	@tipgest=ISNULL(@parXML.value('(/parametri/@tipgest)[1]', 'varchar(1)'), ''), 
	*/@gest=ISNULL(@parXML.value('(/parametri/@gest)[1]', 'varchar(20)'), ''), 
	@cod=ISNULL(@parXML.value('(/parametri/@cod)[1]', 'varchar(20)'), '')

if @codmeniu='VC'
begin
	set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)
	set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)
	if @lunabloc not between 1 and 12 or @anulbloc<=1901 
		set @databloc='01/01/1901' 
	else 
		set @databloc=dbo.EOM(convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))
	
	if @datadoc<=@databloc
		raiserror('Operatia nu se poate da pe o luna inchisa!',11,1)	
	
	if isnull(@nrdoc,'')=''
		raiserror('Selectati o necorelatie si apoi dati operatia!',11,1)
		
	exec luare_date_par 'GE','SUBPRO',0,0,@subunitate OUTPUT	
	exec faInregistrariContabile @dintabela=0, @subunitate=@subunitate, @tip=@tipdoc, @numar=@nrdoc, @data=@datadoc
	
	delete from necorelatii where tip_necorelatii=@tip_necorelatii and utilizator=@userASiS 
		and tip_document=@tipdoc and numar=@nrdoc and data=@datadoc
end

if @codmeniu='VS'
begin
	if @tip_necorelatii in ('SA','RI')
	begin
		if isnull(@cont,'')=''
			raiserror('Selectati o necorelatie si apoi dati operatia!',11,1)
			
		set @dataj=dbo.EOM(@dataj)
		exec RefacereRulaje @dDataJos=@dataj, @dDataSus=@datas, @cCont=''/*@cont *//*am comentat @cont, fiindca, cf. lui Ghita, refacerea funct. corect doar cand se da pe toate ct.*/, 
			@nInLei=1, @nInValuta=1, @cValuta=''

		delete from necorelatii where tip_necorelatii=@tip_necorelatii and utilizator=@userASiS 
			and cont=@cont
	end
	
	if @tip_necorelatii in ('FB','FF')
	begin
		if isnull(@nrdoc,'')=''
			raiserror('Selectati o necorelatie si apoi dati operatia!',11,1)
			
		exec RefacereFacturi @cFurnBenef=@tipdoc, @dData=null, @cTert=@tert, @cFactura=@nrdoc

		delete from necorelatii where tip_necorelatii=@tip_necorelatii and utilizator=@userASiS 
			and tip_document=@tipdoc and numar=@nrdoc and cont=@tert
	end
	
	if @tip_necorelatii='SS'
	begin
		if isnull(@cod,'')=''
			raiserror('Selectati o necorelatie si apoi dati operatia!',11,1)
			
		if @gest='' set @gest=null
		--if @marca='' set @marca=null
		exec RefacereStocuri @cGestiune=@gest, @cCod=@cod, @cMarca=null/*@marca*/, 
			@dData=null, @PretMed=0/*@PretMediu*/, @InlocPret=0/*@inlocpreturi*/ --and @farainlocpretdoc=0
		--exec RefacereSerii @cGestiune=@gest, @cCod=@cod, @dData=null

		delete from necorelatii where tip_necorelatii=@tip_necorelatii and utilizator=@userASiS 
			and numar=@cod and lm=@gest
	end
	
	/*if @tip_necorelatii='SD'
	begin
		if isnull(@decont,'')=''
			raiserror('Selectati o necorelatie si apoi dati operatia!',11,1)
			
		exec RefacereDeconturi @dData='12/31/2999', @cMarca=@marca, @cDecont=@nrdoc

		delete from necorelatii where tip_necorelatii=@tip_necorelatii and utilizator=@userASiS 
			and cont=@cont and tip_document=@tipdoc and numar=@nrdoc and data=@datadoc and lm=@gest
	end
	
	if @tip_necorelatii='SE'
	begin
		if isnull(@efect,'')=''
			raiserror('Selectati o necorelatie si apoi dati operatia!',11,1)
			
		exec RefacereEfecte @dData='12/31/2999', @cTipEf=@tipefect, @cTert=@tert, @cEfect=@nrdoc

		delete from necorelatii where tip_necorelatii=@tip_necorelatii and utilizator=@userASiS 
			and cont=@cont and tip_document=@tipdoc and numar=@nrdoc and data=@datadoc and lm=@gest
	end*/
end
end try 

begin catch  
	set @eroare=ERROR_MESSAGE()+' (wOPRefacereIntegritate)'
	raiserror(@eroare, 11, 1) 		
end catch
