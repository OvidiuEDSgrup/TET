--***
create procedure wScriuRaportActivitati @sesiune varchar(50),@parXML XML      
as  
declare @eroare varchar(50)
set @eroare=''
begin try
	declare @utilizator varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	if exists(select * from sysobjects where name='wScriuRaportActivitatiSP' and type='P')      
	begin	
		exec wScriuRaportActivitatiSP @sesiune,@parXML
		return
	end
	
	declare @Tip_masina varchar(50), @element varchar(50), @ordine smallint, @grupa varchar(50), @update int
	select	@Tip_masina=@parXML.value('(row/@cod)[1]','varchar(20)'),
			@element=@parXML.value('(/row/row/@element)[1]', 'varchar(50)'),
			@ordine=@parXML.value('(/row/row/@ordineRaport)[1]', 'smallint'),
			@grupa=@parXML.value('(/row/row/@grupa)[1]', 'varchar(50)'),
			@update=isnull(@parXML.value('(row/@update)[1]','int'),0)
	
	--> verificari consistenta datelor primite:
		if (@Tip_masina is null) raiserror ('Tipul masinii nu este completat!',16,1)
		if (@grupa is null) raiserror ('Grupa nu este completata!',16,1)
		if (@element is null) raiserror ('Elementul nu a fost identificat!',16,1)
		if (@ordine is null) raiserror ('Ordinea in raport nu este completata!',16,1)
		if (@update=0) raiserror('Este permisa doar modificarea ordinii sau a grupei!',16,1)
	--> modificare
		update em set Grupa=@grupa, em.Ord_raport=@ordine
			from elemtipm em where em.Tip_masina=@Tip_masina and em.Element=@element
end try
begin catch
	set @eroare='wScriuRaportActivitati: '+char(10)+@eroare
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
