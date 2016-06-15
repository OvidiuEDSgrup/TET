CREATE TABLE [dbo].[Contracte] (
    [idContract]             INT            IDENTITY (1, 1) NOT NULL,
    [tip]                    VARCHAR (2)    NULL,
    [numar]                  VARCHAR (20)   NULL,
    [data]                   DATETIME       NULL,
    [tert]                   VARCHAR (20)   NULL,
    [punct_livrare]          VARCHAR (20)   NULL,
    [gestiune]               VARCHAR (20)   NULL,
    [gestiune_primitoare]    VARCHAR (20)   NULL,
    [loc_de_munca]           VARCHAR (20)   NULL,
    [valuta]                 VARCHAR (3)    NULL,
    [curs]                   FLOAT (53)     NULL,
    [valabilitate]           DATETIME       NULL,
    [explicatii]             VARCHAR (8000) NULL,
    [idContractCorespondent] INT            NULL,
    [detalii]                XML            NULL,
    [AWB]                    VARCHAR (200)  NULL,
    CONSTRAINT [PK_Contracte_idContract] PRIMARY KEY CLUSTERED ([idContract] ASC),
    CONSTRAINT [FK_Contracte_ContractCorespondent] FOREIGN KEY ([idContractCorespondent]) REFERENCES [dbo].[Contracte] ([idContract])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [numar]
    ON [dbo].[Contracte]([tip] ASC, [numar] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [con]
    ON [dbo].[Contracte]([tip] ASC, [data] ASC, [numar] ASC, [tert] ASC);


GO
--***
create  trigger tr_ValidContracte on Contracte for insert,update,delete NOT FOR REPLICATION as

DECLARE @mesaj varchar(5000)
begin try	
	-- validare gestiune
	if update(gestiune)
	begin
		-- daca gestiunea nu e NULL, trebuie validata in catalogul de gestiuni
		select @mesaj = ISNULL(@mesaj+' ,', 'Gestiune necompletata sau invalida: ') + inserted.gestiune
		from inserted 
		where gestiune is not null 
		and not exists (select * from gestiuni g where Subunitate='1' and g.Cod_gestiune=inserted.gestiune)
		
		if @mesaj is not null
			raiserror(@mesaj,11, 1)
		end
	
	-- validare tert
	if update(tert)
	begin 
		-- daca tertul nu e NULL, trebuie validat in catalogul de terti
		select @mesaj = ISNULL(@mesaj+' ,', 'Tert necompletat sau invalid: ') + inserted.tert
		from inserted 
		where tert is not null
		and not exists (select * from terti t where Subunitate='1' and t.tert=inserted.tert)
		
		if @mesaj is not null
			raiserror(@mesaj,11, 1)		
	end
	
	-- validare punct livrare
	if update(punct_livrare)
	begin
		select @mesaj = ISNULL(@mesaj+' ,', 'Punct de livrare necompletat sau invalid: ') + inserted.punct_livrare
		from inserted 
		where punct_livrare is not null
		and not exists (select * from infotert it where Subunitate='1' and it.tert=inserted.tert and it.Identificator=punct_livrare and it.Identificator<>'')
		
		if @mesaj is not null
			raiserror(@mesaj,11, 1)
	end
	
	-- validare gestiune
	if update(gestiune_primitoare)
	begin
		-- daca gestiunea primitoare nu e NULL, trebuie validata in catalogul de gestiuni, daca nu e completat tertul
		select @mesaj = ISNULL(@mesaj+' ,', 'Gestiune primitoare necompletata sau invalida: ') + inserted.gestiune_primitoare
		from inserted 
		where gestiune_primitoare is not null
		and not exists (select * from gestiuni g where Subunitate='1' and g.Cod_gestiune=inserted.gestiune_primitoare)
		
		if @mesaj is not null
			raiserror(@mesaj,11, 1)	
	end
	
	-- validare loc de munca
	if update(loc_de_munca)
	begin
		-- daca lm nu e NULL, trebuie validat in catalogul de locuri de munca.
		select @mesaj = ISNULL(@mesaj+' ,', 'Loc de munca necompletat sau invalid: ') + inserted.loc_de_munca
		from inserted 
		where loc_de_munca is not null 
		and not exists (select * from lm where lm.Cod=inserted.loc_de_munca)
		
		if @mesaj is not null
			raiserror(@mesaj,11, 1)
	end
	
	-- validare valuta
	if update(valuta)
	begin
		-- la valuta permit momentan si ''. e corect?
		select @mesaj = ISNULL(@mesaj+' ,', 'Valuta introdusa nu exista in catalogul de valute: ') + inserted.gestiune_primitoare
		from inserted 
		where isnull(valuta,'')<>''
		and not exists (select * from valuta v where v.Valuta=inserted.valuta)
		
		if @mesaj is not null
			raiserror(@mesaj,11, 1)	
	end
	
	-- nu permitem valabilitate contract < data contract
	if update(valabilitate)
	begin
		if exists (select * from inserted where valabilitate<data)
			raiserror('Contractul trebuie sa aiba data valabilitatii ulterioara datei contractului.',11, 1)
	end
	
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+ ' (tr_ValidContracte)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
