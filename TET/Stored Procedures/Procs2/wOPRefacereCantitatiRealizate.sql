--***
create procedure wOPRefacereCantitatiRealizate @sesiune varchar(50), @parXML xml 
as     
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPRefacereCantitatiRealizateUCSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPRefacereCantitatiRealizateSP @sesiune, @parXML output
	return @returnValue
end

declare @stergereRealizari int, @recalculareRealizari int, @contracteFA int,@comenziAprovFC int, @contracteBF int, @comenziLivrBK int,
	@proformeBP int, @datajos datetime, @datasus datetime, @detaliiComProd int, @detaliiComAprov int, @fltContract varchar(20),@sub varchar(9),
	@utilizator varchar(20),@mesaj varchar(250),@tip varchar(2)
begin try 		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1
			
	select 
		@datasus=ISNULL(@parXML.value('(/parametri/@datasus)[1]', 'datetime'), '2090-01-01'),
		@datajos=ISNULL(@parXML.value('(/parametri/@datajos)[1]', 'datetime'), '1901-01-01'),	
		@stergereRealizari=ISNULL(@parXML.value('(/parametri/@stergereRealizari)[1]', 'int'), 0),	
		@recalculareRealizari=ISNULL(@parXML.value('(/parametri/@recalculareRealizari)[1]', 'int'), 0),
		@contracteFA=ISNULL(@parXML.value('(/parametri/@contracteFA)[1]', 'int'), 0),
		@comenziAprovFC=ISNULL(@parXML.value('(/parametri/@comenziAprovFC)[1]', 'int'), 0),
		@contracteBF=ISNULL(@parXML.value('(/parametri/@contracteBF)[1]', 'int'), 0),
		@comenziLivrBK=ISNULL(@parXML.value('(/parametri/@comenziLivrBK)[1]', 'int'), 0),
		@proformeBP=ISNULL(@parXML.value('(/parametri/@proformeBP)[1]', 'int'), 0),
		@detaliiComProd=ISNULL(@parXML.value('(/parametri/@detaliiComProd)[1]', 'int'), 0),	
		@detaliiComAprov=ISNULL(@parXML.value('(/parametri/@detaliiComAprov)[1]', 'int'), 0),
		@fltContract=ISNULL(@parXML.value('(/parametri/@fltContract)[1]', 'varchar(20)'), ''),
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), '')		
	

	select @contracteBF=(case when @tip='BF' then  1 else @contracteBF end), 
		@contracteFA=(case when @tip='FA' then  1 else @contracteFA end) ,
		@comenziLivrBK=(case when @tip='BK' then  1 else @comenziLivrBK end) ,
		@comenziAprovFC=(case when @tip='FC' then  1 else @comenziAprovFC end), 
		@proformeBP=(case when @tip='BP' then  1 else @proformeBP end)

--select @tip,@contracteBF,@fltContract,@stergereRealizari
	if 	@stergereRealizari=1 or (@recalculareRealizari=1 and (@contracteFA=1 or @comenziAprovFC=1 or @contracteBF=1 or @comenziLivrBK=1 or @proformeBP=1))
		or @detaliiComProd=1 or @detaliiComAprov=1
		
		exec  refacereCantRealizate @StergereRealizari=@stergereRealizari, @RecalculareRealizari=@recalculareRealizari, @ContracteFA=@contracteFA,
			@ComenziAprovFC=@comenziAprovFC, @ContracteBF=@contracteBF, @ComenziLivrBK=@comenziLivrBK, @ProformeBP=@proformeBP, @Datajos=@datajos, 
			@Datasus =@datasus, @DetaliiComProd =@detaliiComProd, @DetaliiComAprov =@detaliiComAprov, @FltContract= @fltContract	
	else
		raiserror('Selectati cel putin una din optiunile de pe macheta!',11,1)				
		
	select 'Operatia a fost finalizata!' as textMesaj for xml raw, root('Mesaje')				
end try
begin catch
	set @mesaj='(wOPRefacereCantitatiRealizate)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
