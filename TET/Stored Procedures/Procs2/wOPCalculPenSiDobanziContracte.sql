--***
create procedure wOPCalculPenSiDobanziContracte @sesiune varchar(50), @parXML xml 
as     
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPCalculPenSiDobanziContracteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wCalculPenalitatiContracteSP @sesiune, @parXML output
	return @returnValue
end

declare @dataj datetime,@subunitate varchar(9), @utilizator char(10),@datas datetime,
		@tip varchar(2),@subtip varchar(2),@mesaj varchar(200)
begin try 		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1
		
	declare @data_ucc datetime,@cod varchar(20), @cont_fact_penaliz varchar(20), @comanda varchar(20), @cont_de_stoc varchar(20),
		@indbug varchar(20),@calc_p int	,@calc_d int,@ren_p int,@ren_d int,@stergere_p int,@stergere_d int,
		@factura varchar(20),@tert varchar(13),@contract varchar(20)
	select 
		@datas=ISNULL(@parXML.value('(/parametri/@data_sus)[1]', 'datetime'), ''),
		@dataj=ISNULL(@parXML.value('(/parametri/@data_jos)[1]', 'datetime'), ''),
		@calc_p=ISNULL(@parXML.value('(/parametri/@calc_p)[1]', 'int'), 0),
		@calc_d=ISNULL(@parXML.value('(/parametri/@calc_d)[1]', 'int'), 0),
		@ren_p=ISNULL(@parXML.value('(/parametri/@ren_p)[1]', 'int'), 0),
		@ren_d=ISNULL(@parXML.value('(/parametri/@ren_d)[1]', 'int'), 0),
		@tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(13)'), ''),
		@factura=ISNULL(@parXML.value('(/parametri/@factura)[1]', 'varchar(20)'), ''),
		@contract=ISNULL(@parXML.value('(/parametri/@contract)[1]', 'varchar(20)'), ''),
		@stergere_p=ISNULL(@parXML.value('(/parametri/@stergere_p)[1]', 'int'), 0),
		@stergere_d=ISNULL(@parXML.value('(/parametri/@stergere_d)[1]', 'int'), 0)
			
	declare @input XMl	
	
	--stegregere facturi de penalitati cu numere temporare generate in perioada
	if @stergere_p=1 
	begin
		delete from penalizarifact 
		where tip_penalizare='P' 
			and data_penalizare = @datas
			and (tert=@tert or isnull(@tert,'')='')
			and Stare<>'F'
	end	
	
	--stegregere facturi de dobanzi cu numere temporare generate in perioada
	if @stergere_d=1 
	begin
		delete from penalizarifact 
		where tip_penalizare='D' 
			and data_penalizare = @datas
			and (tert=@tert or isnull(@tert,'')='')
			and Stare<>'F'
	end		
	
	if @calc_p=1 
	begin
		exec calcpen @Dataj=@dataj,@Datas=@datas,@Tert=@tert,@compatibilitateInUrma=0
		exec calcpenNou @Dataj=@dataj,@Datas=@datas,@Tert=@tert
		--select CONVERT(varchar(max),@input)
	end	
	
	if @calc_d=1 
	begin
	
		exec calcdob @Dataj=@dataj,@Datas=@datas,@Tert=@tert,@compatibilitateInUrma=0
		--select CONVERT(varchar(max),@input)
	end	
end try
begin catch
	set @mesaj='(wOPCalculPenSiDobanziContracte)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
begin
	select @mesaj as mesaj
	raiserror(@mesaj, 11, 1)
end
