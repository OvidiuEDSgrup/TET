CREATE TABLE [dbo].[propcomptmp] (
    [Unic]          INT        IDENTITY (1, 1) NOT NULL,
    [HostId]        CHAR (8)   NOT NULL,
    [Valoare_tupla] CHAR (200) NOT NULL,
    [Valoare1]      CHAR (200) NOT NULL,
    [Valoare2]      CHAR (200) NOT NULL,
    [Valoare3]      CHAR (200) NOT NULL,
    [Valoare4]      CHAR (200) NOT NULL,
    [Valoare5]      CHAR (200) NOT NULL,
    [Valoare6]      CHAR (200) NOT NULL,
    [Valoare7]      CHAR (200) NOT NULL,
    [Valoare8]      CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[propcomptmp]([Unic] ASC);


GO
CREATE NONCLUSTERED INDEX [HostId_si_tupla]
    ON [dbo].[propcomptmp]([HostId] ASC, [Valoare_tupla] ASC);


GO
CREATE NONCLUSTERED INDEX [HostId]
    ON [dbo].[propcomptmp]([HostId] ASC);

