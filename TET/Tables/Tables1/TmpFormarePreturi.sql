CREATE TABLE [dbo].[TmpFormarePreturi] (
    [Furnizor]            CHAR (13)  NOT NULL,
    [Data_modificarii]    DATETIME   NOT NULL,
    [Curs]                FLOAT (53) NOT NULL,
    [Grupa_ofertare]      SMALLINT   NOT NULL,
    [Denumire]            CHAR (80)  NOT NULL,
    [Cod]                 CHAR (20)  NOT NULL,
    [Note]                CHAR (150) NOT NULL,
    [UM]                  CHAR (3)   NOT NULL,
    [Pret_intrare]        FLOAT (53) NOT NULL,
    [Pret_vanzare_valuta] FLOAT (53) NOT NULL,
    [Pret_vanzare_lei]    FLOAT (53) NOT NULL,
    [Pret_amanunt_valuta] FLOAT (53) NOT NULL,
    [Pret_amanunt_lei]    FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[TmpFormarePreturi]([Cod] ASC);

