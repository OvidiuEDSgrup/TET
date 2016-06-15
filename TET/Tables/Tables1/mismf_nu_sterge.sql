CREATE TABLE [dbo].[mismf_nu_sterge] (
    [Subunitate]              CHAR (9)   NOT NULL,
    [Data_lunii_de_miscare]   DATETIME   NOT NULL,
    [Numar_de_inventar]       CHAR (13)  NOT NULL,
    [Tip_miscare]             CHAR (3)   NOT NULL,
    [Numar_document]          CHAR (8)   NOT NULL,
    [Data_miscarii]           DATETIME   NOT NULL,
    [Tert]                    CHAR (13)  NOT NULL,
    [Factura]                 CHAR (20)  NOT NULL,
    [Pret]                    FLOAT (53) NOT NULL,
    [TVA]                     FLOAT (53) NOT NULL,
    [Cont_corespondent]       CHAR (13)  NOT NULL,
    [Loc_de_munca_primitor]   CHAR (13)  NOT NULL,
    [Gestiune_primitoare]     CHAR (13)  NOT NULL,
    [Diferenta_de_valoare]    FLOAT (53) NOT NULL,
    [Data_sfarsit_conservare] DATETIME   NOT NULL,
    [Subunitate_primitoare]   CHAR (40)  NOT NULL,
    [Procent_inchiriere]      REAL       NOT NULL
);

