CREATE TABLE [dbo].[tmpBLOB] (
    [HostID] CHAR (8) NOT NULL,
    [Obiect] IMAGE    NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[tmpBLOB]([HostID] ASC);

