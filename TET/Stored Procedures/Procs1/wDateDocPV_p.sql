--***
create procedure wDateDocPV_p @sesiune varchar(50),@parXML xml
as
declare @returnValue int
if exists(select * from sysobjects where name='wDateDocPV_pSP' and type='P')  
begin    
	exec @returnValue =  wDateDocPV_pSP @sesiune,@parXML
	return @returnValue 
end     

declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @tert varchar(50), @gest varchar(50), @lm varchar(50), @categPret varchar(50), @comanda varchar(50),
	@dengestiune varchar(100), @denlm varchar(100), @dencategpret varchar(100), @user varchar(100), @sub varchar(50)

begin try
	exec wIaUtilizator @sesiune,@user output
	
	select	@sub=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @sub end)
	from par 
	where Tip_parametru='GE' and Parametru='SUBPRO'
	
	select	@categPret=ISNULL(@parXML.value('(/row/@categoriePret)[1]', 'int'), '1'), 
			@comanda=ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), ''), 
			@gest=ISNULL(@parXML.value('(/row/@GESTPV)[1]', 'varchar(100)'),rtrim(dbo.wfProprietateUtilizator('GESTPV',@user))),
			@lm=ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(100)'),'')
			
	/*	daca nu e trimis LM in XML din PVria, il iau din proprietati pe utilizator. 
		Daca e o comanda pe bonul respectiv, iau lm de pe comanda de livrare
		Daca nu e nici acolo, iau LM asociat gestiunii. */
	
	if @lm=''
	begin
		set @LM = rtrim(dbo.wfProprietateUtilizator('LOCMUNCA',@user))
		if isnull(@comanda,'')!=''
			select top 1 @LM=loc_de_munca /*, @comandaASiS= de facut*/ from con where subunitate=@sub and tip='BK' and Contract=@comanda /*-- nu merge and (@cDataComenzii is null or Data=convert(datetime,@cDataComenzii,103))*/
			order by data desc

		if @LM='' /* LM = '' daca nu este proprietatea */
			set @LM = (select rtrim(max(Loc_de_munca)) from gestcor where Gestiune=@gest)
	end

			
	select @dengestiune = rtrim(Denumire_gestiune) from gestiuni g where g.Cod_gestiune=@gest
	select @dencategpret = rtrim(Denumire) from categpret c where c.Categorie=@categPret
	select @denlm = RTRIM(denumire) from lm where lm.Cod=@lm

	select @categPret categoriePret, @dencategpret dencategoriePret, @comanda comanda, @comanda dencomanda, @gest GESTPV, @dengestiune denGESTPV, @lm lm, @denlm denlm
	for xml raw
		
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )

end catch

	
	
