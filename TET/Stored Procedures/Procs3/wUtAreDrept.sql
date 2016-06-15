--***
create procedure wUtAreDrept @sesiune varchar(50),@ut varchar(100),@parola varchar(100),@drept varchar(100)
as
	declare @raspuns varchar(100)
	set @parola=UPPER(@parola)
	set @raspuns='ok'

	if not exists(select * from utilizatori u where u.ID=@ut and u.Parola=dbo.wfAdunScad('C',@parola,'PAROLA'))
		set @raspuns='Parola este gresita.'
	
	if @raspuns='ok'
	begin
		if not exists(select drept from dreptutiliz du where id=@ut and drept=@drept and tip='U')
			set @raspuns='Nu aveti drepturi suficiente'
		if @raspuns<>'ok' and exists(select drept from dreptutiliz where dreptutiliz.Drept=@drept and ID in 
			(select ID from gruputiliz where gruputiliz.ID_utilizator=@ut))
			set @raspuns='ok'
    end
    SELECT @raspuns as raspuns
    FOR XML RAW
