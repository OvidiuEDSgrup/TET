
create procedure  wScriuConturiBanca @sesiune varchar(50), @parXML xml  
as
begin try
	declare	@mesajeroare varchar(500),@utilizator char(10),@sub char(9)
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1

	DECLARE @tert varchar(30),@cont_in_banca varchar(35),@banca varchar(20),@update bit,@numar_pozitie int
--sp_help contbanci
	select  
		@tert= isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),''),
		@banca= upper(isnull(@parXML.value('(/row/row/@banca)[1]','varchar(20)'),'')),
		@cont_in_banca= upper(isnull(@parXML.value('(/row/row/@cont_in_banca)[1]','varchar(35)'),'')),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@numar_pozitie = isnull(@parXML.value('(/row/row/@numar_pozitie)[1]','int'),0)		
 
	if exists (select 1 from sys.objects where name='wScriuConturiBancaSP' and type='P')  
		exec wScriuConturiBancaSP @sesiune, @parXML
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	
	if @update=1
	begin	
		update ContBanci set Banca=@banca,Cont_in_banca=@cont_in_banca
		where Subunitate=@sub and tert=@tert and Numar_pozitie=@numar_pozitie
	end	
	else
	begin
		set @numar_pozitie=isnull((select MAX(numar_pozitie) from ContBanci),0)+1
		insert into ContBanci(Subunitate,Tert,Numar_pozitie,Banca,Cont_in_banca)
		select @sub,@tert,@numar_pozitie,@banca,@cont_in_banca
	end	
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
