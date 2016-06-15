CREATE TABLE [dbo].[utilizatori] (
    [ID]         CHAR (10)  NOT NULL,
    [Nume]       CHAR (30)  NOT NULL,
    [Parola]     CHAR (10)  NOT NULL,
    [Info]       CHAR (100) NOT NULL,
    [Categoria]  SMALLINT   NOT NULL,
    [Jurnal]     CHAR (3)   NOT NULL,
    [Marca]      CHAR (6)   NOT NULL,
    [Observatii] CHAR (30)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ID]
    ON [dbo].[utilizatori]([ID] ASC);


GO

CREATE TRIGGER wTrigRia 
ON utilizatori
FOR INSERT, UPDATE, DELETE
AS
		-- sterg din ASiSria..utilizatoriRia, utilizatorii modficati.
	DELETE u FROM ASiSRIA.dbo.utilizatoriRIA u
	WHERE u.bd = db_name() 
	and ( EXISTS (SELECT 1 FROM DELETED d WHERE d.id = u.utilizator ) -- utilizatori modificati
		-- sterg si utilizatorii care tomai se insereaza - ar putea sa existe deja in tabela 
		-- utilizatoriRIA, daca se face un backup/restore si se readauga aceeasi useri.
		or EXISTS (SELECT 1 FROM INSERTED d WHERE d.id = u.utilizator ) ) 
	
	-- inserez in ASiSria..utilizatoriRia, utilizatorii modficati.
	INSERT INTO ASiSRIA.dbo.utilizatoriRIA(bd,utilizator,parola,utilizatorWindows)
	SELECT db_name(),RTRIM(id),RTRIM(info),RTRIM(observatii)
	FROM INSERTED where inserted.id<>''

	-- actualizez parola pentru utilizator - un user poate avea o singura parola MD5 aici
	-- 2011-08-15 - mitz - permitem sa aiba parole diferite pe baze de date diferite... se va trata si in web service...
	/*update ASiSRIA.dbo.utilizatoriRIA 
	set parola=rtrim(i.info)
	from inserted i , ASiSRIA.dbo.utilizatoriRIA u
	where i.ID=u.utilizator and u.BD<>DB_NAME()*/


GO
--***
create trigger tr_modif_utilizator on utilizatori for update, delete
as
declare @eroare varchar(2000)
begin try
	declare @updatat varchar(10), @anterior varchar(10), @ria int, @inserate int, @sterse int, @modifCod int
	select @ria=1, @inserate=0, @sterse=0, @modifCod=0
		--> se verifica daca e tip ria (adica daca exista tabele ria); proprietatile trebuie mentinute si pe partea de ASiSplus
	if not exists (select 1 from sysobjects s where s.name='webConfigMeniuUtiliz') or
		not exists (select 1 from sysobjects s where s.name='webConfigRapoarte')
	select @ria=0

	select @inserate=count(1) from inserted i
	select @sterse=count(1) from deleted d
	select @modifCod=count(1) from inserted i where not exists (select 1 from deleted d where d.id=i.id)
	
	if (@inserate>1 or @inserate>0 and @sterse>1) and @modifCod>=1
		raiserror('Nu e permisa modificarea masiva a codurilor de utilizatori deoarece nu se poate mentine integritatea configurarilor! Modificati codurile pentru fiecare utilizator pe rand!',16,1)
	
	select @updatat=i.ID from inserted i where @inserate>0 and not exists (select 1 from deleted d where d.ID=i.ID)
	select @anterior=d.ID from deleted d
	
	if @updatat is not null
	begin
		if @ria=1
			update w set IdUtilizator=@updatat
			from webConfigMeniuUtiliz w where w.IdUtilizator=@anterior
		
		if @ria=1
			update r set utilizator=@updatat
			from webConfigRapoarte r where r.utilizator=@anterior
		
		update p set cod=@updatat
		from proprietati p where p.Cod=@anterior and p.Tip='UTILIZATOR'
	end
	else
	if @modifCod=0
	begin
		if @ria=1
			delete w from webConfigMeniuUtiliz w inner join deleted d on w.IdUtilizator=d.ID
				where not exists (select 1 from inserted i where i.id=d.id)
		if @ria=1
			delete r from webConfigRapoarte r inner join deleted d on r.utilizator=d.ID
				where not exists (select 1 from inserted i where i.id=d.id)
		delete p from proprietati p inner join deleted d on p.Cod=d.ID and p.Tip='UTILIZATOR'
			where not exists (select 1 from inserted i where i.id=d.id)
	end
end try
begin catch
	set @eroare=ERROR_MESSAGE()+char(13)+'(tr_modif_utilizator)'
	raiserror(@eroare,16,1)
end catch

GO
--***
create  trigger tr_validUtilizator on utilizatori for insert,update NOT FOR REPLICATION as
begin
	declare @eroare varchar(1000)
	set @eroare=''
	begin try
		
		--if exists (select 1 from utilizatori u where u.ID<>inserted.id and u.Observatii=inserted.observatii)
			select @eroare='Utilizatorul Windows "'+rtrim(i.observatii)+'" este deja folosit pentru utilizatorul "'+rtrim(u.id)+'" !'
				from utilizatori u, inserted i 
				where u.ID<>i.id and u.Observatii=i.observatii and i.Observatii<>''
			if len(@eroare)>0 raiserror(@eroare,16,1)
	end try
	begin catch
		set @eroare=@eroare+char(13)+'(tr_validUtilizator)'
		raiserror (@eroare,16,1)
	end catch
end
