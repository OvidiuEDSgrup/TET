CREATE TABLE [dbo].[evidprodanuala] (
    [subunitate]              CHAR (9)   NOT NULL,
    [anul]                    SMALLINT   NOT NULL,
    [cod_produs]              CHAR (20)  NOT NULL,
    [comanda]                 CHAR (13)  NOT NULL,
    [data_lansarii]           DATETIME   NOT NULL,
    [data_inchiderii]         DATETIME   NOT NULL,
    [cantitate_lansata]       FLOAT (53) NOT NULL,
    [ramas_din_anul_anterior] FLOAT (53) NOT NULL,
    [cumulat_cant_lansata]    FLOAT (53) NOT NULL,
    [total_cumulat]           FLOAT (53) NOT NULL,
    [luna_I]                  FLOAT (53) NOT NULL,
    [realizat_luna_I]         FLOAT (53) NOT NULL,
    [luna_II]                 FLOAT (53) NOT NULL,
    [realizat]                FLOAT (53) NOT NULL,
    [luna_III]                FLOAT (53) NOT NULL,
    [realizat_luna_III]       FLOAT (53) NOT NULL,
    [luna_IV]                 FLOAT (53) NOT NULL,
    [realizat_luna_IV]        FLOAT (53) NOT NULL,
    [luna_V]                  FLOAT (53) NOT NULL,
    [realizat_luna_V]         FLOAT (53) NOT NULL,
    [luna_VI]                 FLOAT (53) NOT NULL,
    [realizat_luna_VI]        FLOAT (53) NOT NULL,
    [luna_VII]                FLOAT (53) NOT NULL,
    [realizat_luna_VII]       FLOAT (53) NOT NULL,
    [luna_VIII]               FLOAT (53) NOT NULL,
    [realizat_luna_VIII]      FLOAT (53) NOT NULL,
    [luna_IX]                 FLOAT (53) NOT NULL,
    [realizat_luna_IX]        FLOAT (53) NOT NULL,
    [luna_X]                  FLOAT (53) NOT NULL,
    [realizat_luna_X]         FLOAT (53) NOT NULL,
    [luna_XI]                 FLOAT (53) NOT NULL,
    [realizat_luna_XI]        FLOAT (53) NOT NULL,
    [luna_XII]                FLOAT (53) NOT NULL,
    [realizat_luna_XII]       FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [unic]
    ON [dbo].[evidprodanuala]([cod_produs] ASC, [comanda] ASC, [data_lansarii] ASC, [cantitate_lansata] ASC);

