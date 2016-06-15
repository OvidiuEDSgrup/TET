--***
create procedure wRenumerotareDobanziContracte @sesiune varchar(50), @parXML xml 
as     
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRenumerotareDobanziContracteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRenumerotareDobanziContracteSP @sesiune, @parXML output
	return @returnValue
end

declare @dataj datetime,@subunitate varchar(9), @utilizator char(10),@datas datetime,
	@mesaj varchar(200),@cod varchar(20)
begin try 		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1
		
	select 
		@datas=ISNULL(@parXML.value('(/row/@datas)[1]', 'datetime'), ''),
		@cod=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''),
		@dataj=ISNULL(@parXML.value('(/row/@datas)[1]', 'datetime'), '')	

	declare @numar_aviz varchar(8)
	set @numar_aviz=0 
	--set @cod='95002'

	declare @numar varchar(20), @tert varchar(20), @data datetime     

	select @numar_aviz=max(convert(decimal(20),factura))+1 from pozdoc p where tip in ('AP','AS') and isnumeric(p.factura)<>0 and year(data)=year(@datas) and len(factura)<6
	select numar, tert, data into #pozdoc from pozdoc where cod_intrare = 'APBK'
		 and subunitate = '1' and tip = 'AS' and data =  @datas and cod=@cod and left(numar,2)='D#'

	declare numardoc_ramase cursor
	for select numar, tert, data
	from #pozdoc
	order by tert
	
	open numardoc_ramase            
	fetch next from numardoc_ramase into @numar, @tert, @data      
	while (@@fetch_status=0)
	begin
		update penalizarifact set factura=@numar_aviz from pozdoc p 
		where penalizarifact.tert=p.tert and penalizarifact.factura=p.factura 
		and p.tip = 'AS'  and p.data = @datas and p.subunitate='1' and p.cod=@cod and p.numar = @numar and p.tert=@tert

		update pozdoc 
		set numar = @Numar_aviz, factura=@numar_aviz
		where numar = @numar and tert=@tert and cod_intrare = 'APBK'
		and subunitate = '1' and tip = 'AS' and data =  @datas
		set @numar_aviz=@numar_aviz+1
		fetch next from numardoc_ramase into @numar, @tert, @data 
	end
	close numardoc_ramase
	deallocate numardoc_ramase
	drop table #pozdoc

	update penalizarifact set factura='S'+factura where left(factura,2)='D#' and data_penalizare=@datas
	delete from facturi where left(factura,2)='D#'
	delete from doc where numar_dvi='Dobanzi' and tip='AS' and data= @datas and left(factura,2)='D#'
end try
begin catch
	set @mesaj=ERROR_MESSAGE()
end catch

declare @cursorStatus int
set @cursorStatus=(select max(convert(int,is_open)) from sys.dm_exec_cursors(0) where name='numardoc_ramase' and session_id=@@SPID )
if @cursorStatus=1
	close numardoc_ramase
if @cursorStatus is not null
	deallocate numardoc_ramase

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
