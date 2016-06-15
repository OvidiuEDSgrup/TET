CREATE TABLE [dbo].[selfactachit] (
    [HostID]     CHAR (8)   NOT NULL,
    [Subunitate] CHAR (9)   NOT NULL,
    [Tip]        BINARY (1) NOT NULL,
    [Tert]       CHAR (13)  NOT NULL,
    [Factura]    CHAR (20)  NOT NULL,
    [Selectat]   BIT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[selfactachit]([HostID] ASC, [Subunitate] ASC, [Tip] ASC, [Factura] ASC, [Tert] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Tert_Tip]
    ON [dbo].[selfactachit]([HostID] ASC, [Subunitate] ASC, [Tert] ASC, [Tip] ASC);

