CREATE TABLE [dbo].[Oportunitati] (
    [idOportunitate]           INT            IDENTITY (1, 1) NOT NULL,
    [idLead]                   INT            NULL,
    [idPotential]              INT            NULL,
    [descriere]                VARCHAR (2000) NULL,
    [topic]                    VARCHAR (200)  NULL,
    [data_inchiderii_estimata] DATETIME       NULL,
    [vanzare_estimata]         FLOAT (53)     NULL,
    [probabilitate]            FLOAT (53)     NULL,
    [rating]                   VARCHAR (100)  NULL,
    [valuta]                   VARCHAR (100)  NULL,
    [stare]                    VARCHAR (100)  NULL,
    [data_operarii]            DATETIME       DEFAULT (getdate()) NULL,
    [supervizor]               VARCHAR (200)  NULL,
    [detalii]                  XML            NULL,
    PRIMARY KEY CLUSTERED ([idOportunitate] ASC)
);

