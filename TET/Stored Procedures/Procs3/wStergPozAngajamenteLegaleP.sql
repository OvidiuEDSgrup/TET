create procedure  [dbo].[wStergPozAngajamenteLegaleP] @sesiune varchar(50), @parXML xml
as
begin try
begin transaction
	DECLARE @indbug varchar(20),@numar_ordonantare varchar(9),@data_ordonantare datetime  ,@numar varchar(9),
	        @numar_pozitie varchar(9),@data_OP datetime,@subtip varchar(2) ,@data_CFP datetime    
        
     select
         @indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
         @numar_ordonantare = isnull(@parXML.value('(/row/@numar_ordonantare)[1]','varchar(9)'),''),
         @data_ordonantare = isnull(@parXML.value('(/row/@data_ordonantare)[1]','datetime'),''),
         
         @subtip = isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),''),
         @numar_pozitie = isnull(@parXML.value('(/row/row/@nr_pozitie)[1]','varchar(9)'),''),        
         @numar = isnull(@parXML.value('(/row/row/@numar)[1]','varchar(9)'),''),         
         @data_OP = isnull(@parXML.value('(/row/row/@data_OP)[1]','datetime'),''),
         @data_CFP = isnull(@parXML.value('(/row/row/@data_CFP)[1]','datetime'),'')
         
         
declare @mesajeroare varchar(100)
begin
	if @subtip='OP'
		begin
			delete from pozncon where tip='AO' and numar=@numar and comanda=space(20)+@indbug
									and data=@data_OP and  cont_creditor='8067'
			delete from pozordonantari where numar_ordonantare=@numar_ordonantare and numar_OP=@numar and data_OP=@data_OP
										  and indicator=@indbug
		end
	
	if @subtip='VO'
		begin
				
			if exists(select 1 from pozordonantari where numar_ordonantare=@numar_ordonantare and Data_ordonantare=@data_ordonantare )
				raiserror('Nu poate fi stearsa viza CFP intrucat pe aceasta ordonantare sunt Ordine de plata!!!',11,1)
			
			delete from pozncon where subunitate='1' and tip='AO' and numar=@numar_ordonantare 
									and data=@data_ordonantare
									and Cont_creditor='8066'
									
			delete from pozncon where subunitate='1' and tip='AO' and numar=@numar_ordonantare 
									and data=@data_ordonantare
									and Cont_debitor='8067'									
			
			delete from registrucfp where indicator=@indbug and Numar=@numar_ordonantare and data=@data_ordonantare
										and Numar_CFP=@numar and Data_CFP=@data_CFP	
		end	
commit transaction		
declare @docXMLIaPozOrd xml
set @docXMLIaPozOrd = '<row numar_ordonantare="' + rtrim(@numar_ordonantare)+'" indbug="'+rtrim(@indbug)+'" data_ordonantare="' + convert(char(10), @data_ordonantare, 101) +'"/>'
	exec wIaPozAngajamenteLegale @sesiune=@sesiune, @parXML=@docXMLIaPozOrd
end
end try
begin catch
	rollback transaction
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
--select * from registrucfp
