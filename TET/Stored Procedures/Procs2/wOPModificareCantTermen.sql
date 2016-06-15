--***
create procedure wOPModificareCantTermen @sesiune varchar(50), @parXML xml 
as     
begin try 
declare  @TermPeSurse int,@f_sursa varchar(13), @iDoc int ,@numarpoz int ,@data_pret datetime,@n_cantitate float,@cod varchar(20),
		@tert varchar(13),@contract varchar(20),@schimbare_pret_nomencl bit,@sub varchar(1), @utilizator char(10),
		@f_contract varchar(20),@data datetime,@termen datetime,@pozitii int
		
	exec luare_date_par 'UC', 'POZSURSE', 0, 0, @TermPeSurse output
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	set @Utilizator=dbo.fIaUtilizator(null)

	select 
	   @cod=ISNULL(@parXML.value('(/parametri/row/@cod)[1]', 'varchar(20)'), ''),
	   @pozitii=ISNULL(@parXML.value('(/parametri/@pozitii)[1]', 'int'), ''),
	   @data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),
	   @termen=ISNULL(@parXML.value('(/parametri/row/@Ttermen)[1]', 'datetime'), ''),
	   @tert=ISNULL(@parXML.value('(/parametri/row/@Ttert)[1]', 'varchar(20)'), ''),
	   @contract=ISNULL(@parXML.value('(/parametri/row/@Tcontract)[1]', 'varchar(20)'), ''),
	   @n_cantitate=ISNULL(@parXML.value('(/parametri/@n_cantitate)[1]', 'float'), '')
	   	   

	if @cod='' or @tert='' or not exists (select cod from nomencl where cod=@cod)
	 	raiserror('wOPModificareCantTermen:Selectati un termen pentru modificare cantitatii!!',11,1)	
	
	update termene set Cantitate=@n_cantitate
	where subunitate=@sub 
		and tip='BF' 
		and contract=@contract 
		and ((cod=@cod and @TermPeSurse=0) or (cod=@pozitii and @TermPeSurse=1)) 
		and tert=@tert
		and data=@data
		and termen=@termen	
	
	update pozcon set cantitate=isnull((select SUM(cantitate) from Termene 
	                  where Subunitate=@sub and tip='BF' and contract=@contract
	                  and tert=@tert and Data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@pozitii)) end)),0)
	where subunitate=@sub and tip='BF' and Contract=@contract and Tert=@tert and Cod=@cod  and data=@data
		
	update con set Total_contractat=isnull((select SUM(round(cantitate*pret,2)) from Termene 
	                                        where subunitate=@sub and tip='BF' and contract=@contract and tert=@tert and data=@data),0)
	where tip='BF' and contract=@contract and tert=@tert and data=@data and subunitate=@sub	
		
end try
begin catch
declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 11, 1)
end catch
--select * from pozcon
