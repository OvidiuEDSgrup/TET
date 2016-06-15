CREATE TABLE [dbo].[gestiuni] (
    [Subunitate]             CHAR (9)     NOT NULL,
    [Tip_gestiune]           CHAR (1)     NOT NULL,
    [Cod_gestiune]           CHAR (9)     NOT NULL,
    [Denumire_gestiune]      CHAR (43)    NOT NULL,
    [Cont_contabil_specific] VARCHAR (20) NULL,
    [detalii]                XML          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[gestiuni]([Subunitate] ASC, [Cod_gestiune] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[gestiuni]([Denumire_gestiune] ASC);


GO
--***
CREATE trigger gestiunisterg on gestiuni for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssg
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Subunitate, Tip_gestiune, Cod_gestiune, Denumire_gestiune, Cont_contabil_specific
   from deleted

GO

create  trigger tr_validGestiuni on gestiuni for update, delete not for replication
as
begin try

	-- Daca exista codul de gestiune in tabela deleted si nu exista in inserted -> se incearca stergerea gestiunii
	if exists (select 1 from deleted) and not exists(select 1 from inserted)
	begin
		if exists (select 1 from deleted d join pozdoc p on d.Subunitate=p.Subunitate
							and ((d.Cod_gestiune=p.Gestiune and p.Tip not in('PF','CI','AF')) or (d.Cod_gestiune=p.Gestiune_primitoare and p.Tip='TE')))
			raiserror('Gestiunea nu poate fi stearsa. Exista miscari in pozdoc pe aceasta gestiune.',16,1)
	end 

	-- Daca exista pozitii in tabela deleted si exista si in inserted -> se incearca modificarea gestiunii
	if exists (select 1 from deleted) and exists(select 1 from inserted)
	begin
		if not exists(select 1 from deleted d join inserted i on d.Subunitate=i.Subunitate and d.Cod_gestiune=i.Cod_gestiune) 
			and exists (select 1 from deleted d join pozdoc p on d.Subunitate=P.Subunitate 
							and ((d.Cod_gestiune=p.Gestiune and p.Tip not in('PF','CI','AF')) or (d.Cod_gestiune=p.Gestiune_primitoare and p.Tip='TE')))
				raiserror('Codul gestiunii nu poate fi modificat. Exista miscari in pozdoc pe aceasta gestiune.',16,1)
	end 

end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch
