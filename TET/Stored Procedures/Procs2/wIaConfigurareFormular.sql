--***

CREATE procedure wIaConfigurareFormular @sesiune varchar(50), @parXML xml  
as
declare @conf xml, @formular varchar(16), @cale varchar(200), @eroare varchar(200), @ok smallint


Set @formular = rtrim(@parXML.value('(/row/@formular)[1]','varchar(16)')) 
set @cale =(select rtrim(val_alfanumerica) from par where parametru='CALEFORM')
set @ok=1

if ((select continut from XMLFormular where numar_formular = @formular)IS NULL )
begin
	set @ok=0
	set @eroare = 'Nu este setat sablonul de constructie al formularului!'
	raiserror (@eroare ,11 ,1)
end

if ((select count(*) from formular where formular = @formular) <1 )
begin
	set @ok=0
	set @eroare = 'Nu sunt setate obiecte pentru acest formular! '
	raiserror (@eroare ,11 ,1)
end
if (@ok =1)
begin
	set @conf=(
					select 
					(
						select continut as continut, versiune as versiune from XMLFormular as Sablon where numar_formular =@formular for xml auto,type
					) as Conf,
					(
						select rtrim(obiect)  from formular  where formular=@formular for xml path('Obiect') ,type
					) as ObiecteFormular
					
		for xml path('Configurari'), root ('Date')
	)

	set @conf.modify('insert attribute cale {sql:variable("@cale")} into (Date/Configurari/Conf/Sablon)[1]')	

	select @conf
end
