package com.vsoft.service;

import com.vsoft.model.Course;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class CourseService {

    List<Course> list = new ArrayList<>();

    public List<Course> getAllCourses(){
        log.info("getAllCourses method called.");
        log.info("Course List size :"+list.size());
        return list;
    }

    public Course getCourseById(Long id){
        log.info("getCourseById method called.");
        return list.stream().filter(x->x.getId().equals(id)).findFirst().orElseThrow();
    }

    public Course addCourse(Course course){
        System.out.println("Course name:"+course.getCourseName());
        log.info("addCourse method called.");
        list.add(course);
        return course;
    }

    public void deleteCourse(Long id){
        log.info("deleteCourse method called.");
        list.removeIf(x->x.getId().equals(id));
    }

    public Course updateCourse(Course course){
        log.info("updateCourse method called.");
        Course existingCourse = list.stream().filter(x->x.getId().equals(course.getId())).findFirst().get();
        existingCourse.setCourseName(course.getCourseName());
        existingCourse.setDuration(course.getDuration());
        existingCourse.setAmount(course.getAmount());
        list.add(existingCourse);
        log.info("Course updated successfully");
        return existingCourse;
    }
}
