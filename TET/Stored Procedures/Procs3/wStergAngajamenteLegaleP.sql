create procedure  [dbo].[wStergAngajamenteLegaleP] @sesiune varchar(50), @parXML xml
as
begin try
	DECLARE @indbug varchar(20),@numar_ordonantare varchar(9),@data_ordonantare datetime ,@numar_ang_legal varchar(8)  ,
		@data_ang_legal datetime,@mesajeroare varchar(100)     
        
	select
         @indbug = @parXML.value('(/row/@indbug)[1]','varchar(20)'),
         @numar_ordonantare = @parXML.value('(/row/@numar_ordonantare)[1]','varchar(9)'),
         @numar_ang_legal = @parXML.value('(/row/@numar_ang_legal)[1]','varchar(9)'),
         @data_ordonantare = @parXML.value('(/row/@data_ordonantare)[1]','datetime'),
         @data_ang_legal = @parXML.value('(/row/@data_ang_legal)[1]','datetime')
   
   	if exists (select 1 from registrucfp r where r.indicator=@indbug and r.numar=@numar_ordonantare
                       and r.data=@data_ordonantare and r.tip='O')                        
		raiserror( 'Angajamentul legal/Ordonantarea are vize cfp si nu poate fi sters!!',11,1) 

	delete from ordonantari where numar_ordonantare=@numar_ordonantare and data_ordonantare=@data_ordonantare	
	delete from pozncon where tip='AO' and numar=@numar_ang_legal and data=@data_ang_legal and cont_debitor='' and cont_creditor='8066'
	delete from pozncon where tip='AO' and numar=@numar_ang_legal and data=@data_ang_legal and cont_debitor='8067' and cont_creditor=''

end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
