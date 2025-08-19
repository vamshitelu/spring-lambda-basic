package com.vsoft.service;

import com.vsoft.model.Course;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class CourseService {

    List<Course> list = new ArrayList<>();

    public List<Course> getAllCourses(){
        return list;
    }

    public Course getCourseById(Long id){
        return list.stream().filter(x->x.getId().equals(id)).findFirst().get();
    }

    public Course addCourse(Course course){
        list.add(course);
        return course;
    }

    public void deleteCourse(Long id){
        list.removeIf(x->x.getId().equals(id));
    }

    public Course updateCourse(Course course){
        Course existingCourse = list.stream().filter(x->x.getId().equals(course.getId())).findFirst().get();
        existingCourse.setCourseName(course.getCourseName());
        existingCourse.setDuration(course.getDuration());
        existingCourse.setAmount(course.getAmount());
        list.add(existingCourse);
        return existingCourse;
    }
}
