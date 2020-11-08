CREATE TABLE users (
    id uuid NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    CONSTRAINT users_id PRIMARY KEY (id),
    CONSTRAINT users_email UNIQUE (email)
);


CREATE TABLE classes (
    id uuid NOT NULL,
    teacher_id uuid NOT NULL,
    title text NOT NULL,
    starts_at timestamp NOT NULL,
    ends_at timestamp NOT NULL,
    CONSTRAINT classes_id PRIMARY KEY (id),
    CONSTRAINT classes_teacher_fkey FOREIGN KEY (teacher_id) REFERENCES users(id) ON UPDATE CASCADE NOT DEFERRABLE
);

CREATE INDEX classes_teacher ON classes USING btree (teacher_id);

CREATE INDEX classes_starts_at ON classes USING btree (starts_at);


CREATE TABLE attendances (
    class_id uuid NOT NULL,
    user_id uuid NOT NULL,
    hits integer DEFAULT '1' NOT NULL,
    first_seen_at timestamp DEFAULT now() NOT NULL,
    last_seen_at timestamp DEFAULT now() NOT NULL,
    CONSTRAINT attendances_ids PRIMARY KEY (class_id, user_id),
    CONSTRAINT attendances_class_id_fkey FOREIGN KEY (class_id) REFERENCES classes(id) ON UPDATE CASCADE NOT DEFERRABLE,
    CONSTRAINT attendances_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE NOT DEFERRABLE
);

CREATE INDEX attendances_class_id ON attendances USING btree (class_id);

CREATE INDEX attendances_user_id ON attendances USING btree (user_id);